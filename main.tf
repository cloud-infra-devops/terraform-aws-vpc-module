data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use only as many AZs as the max subnets requested
  max_subnets = max(var.num_public_subnets, var.num_private_subnets)
  azs         = slice(data.aws_availability_zones.available.names, 0, local.max_subnets)

  # Number of NAT gateways: one per AZ or just one
  nat_count = var.create_nat_gateway ? (var.single_nat_gateway ? 1 : var.num_public_subnets) : 0

  common_tags = merge(var.tags, { Name = var.name })
}

# ─── VPC ────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, { Name = var.name })
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-default-sg" })
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count      = var.secondary_vpc_cidr != null ? 1 : 0
  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_vpc_cidr
}

# ─── INTERNET GATEWAY ───────────────────────────────────────────────────────

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-igw" })
}

# ─── PUBLIC SUBNETS ─────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count                   = var.num_public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = false
  tags                    = merge(local.common_tags, { Name = "${var.name}-public-${count.index + 1}", Tier = "public" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = var.num_public_subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─── NAT GATEWAY ────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.name}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.common_tags, { Name = "${var.name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

# ─── PRIVATE SUBNETS (per layer) ────────────────────────────────────────────
# Subnet CIDR offset: public subnets use indices 0..(num_public-1)
# Private layer l, subnet s → offset = num_public + (l * num_private) + s

resource "aws_subnet" "private" {
  # total = num_layers * num_private_subnets
  count             = var.num_layers * var.num_private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.num_public_subnets + count.index)
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(local.common_tags, {
    Name  = "${var.name}-private-layer${floor(count.index / var.num_private_subnets) + 1}-${count.index % var.num_private_subnets + 1}"
    Tier  = "private"
    Layer = tostring(floor(count.index / var.num_private_subnets) + 1)
  })
}

# One route table per private subnet (or per AZ if single NAT)
resource "aws_route_table" "private" {
  count  = var.num_layers * var.num_private_subnets
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-private-rt-${count.index + 1}" })
}

# Route to 0.0.0.0/0 via NAT — only created when NAT gateway exists
resource "aws_route" "private_nat" {
  count = var.create_nat_gateway ? var.num_layers * var.num_private_subnets : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # If single NAT, always use index 0; otherwise round-robin across NAT GWs
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index % local.nat_count].id
}

resource "aws_route_table_association" "private" {
  count          = var.num_layers * var.num_private_subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

locals {
  # private subnet tags for running eks
  _private_subnet_eks_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
  private_subnet_tags = var.enable_eks_subnet_tags ? local._private_subnet_eks_tags : {}

  # public subnet tags for running eks
  _public_subnet_eks_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
  public_subnet_tags = var.enable_eks_subnet_tags ? local._public_subnet_eks_tags : {}
}

# vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(
    { "Name" = var.vpc_name },
    var.tags,
  )
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { "Name" = "${var.vpc_name}-igw" },
    var.tags,
  )
}

# private subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.availability_zones[count.index].private_subnet_cidr
  availability_zone = var.availability_zones[count.index].az_name
  tags = merge(
    { "Name" = "${var.vpc_name}-private-subnet-${var.availability_zones[count.index].az_name}"  },
    var.tags,
    local.private_subnet_tags
  )
}

# private route tables, one per subnet
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { "Name" = "${var.vpc_name}-private-rt-${var.availability_zones[count.index].az_name}"  },
    var.tags
  )
}

# private default route to NAT gateway
resource "aws_route" "private-ngw" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[count.index].id
}

# private route table association
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# public subnet
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.availability_zones[count.index].public_subnet_cidr
  availability_zone = var.availability_zones[count.index].az_name

  tags = merge(
    { "Name" = "${var.vpc_name}-public-subnet-${var.availability_zones[count.index].az_name}"  },
    var.tags,
    local.public_subnet_tags
  )

  depends_on = [aws_internet_gateway.igw]
}

# public route tables, one per subnet
resource "aws_route_table" "public" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { "Name" = "${var.vpc_name}-public-rt-${var.availability_zones[count.index].az_name}"  },
    var.tags
  )
}

# public routes to IGW
resource "aws_route" "public-igw" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# public route table association
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# public nat gateway
resource "aws_eip" "ngw" {
  count = length(var.availability_zones)

  vpc = true
  tags = merge(
    { "Name" = "${var.vpc_name}-ngw-${var.availability_zones[count.index].az_name}"  },
    var.tags,
  )
}

resource "aws_nat_gateway" "ngw" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = merge(
    { "Name" = "${var.vpc_name}-ngw-${var.availability_zones[count.index].az_name}"  },
    var.tags,
  )

  depends_on = [aws_internet_gateway.igw]
}

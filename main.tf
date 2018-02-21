resource "aws_vpc" "mod" {
  provider             = "${var.provider}"
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "mod" {
  provider = "${var.provider}"
  vpc_id = "${aws_vpc.mod.id}"
}

resource "aws_route_table" "public" {
  provider         = "${var.provider}"
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.public_propagating_vgws}"]

  tags {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "public_internet_gateway" {
  provider               = "${var.provider}"
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.mod.id}"
}

resource "aws_route_table" "private" {
  provider         = "${var.provider}"
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]

  tags {
    Name = "${var.name}-private"
  }
}

resource "aws_subnet" "private" {
  provider          = "${var.provider}"
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${var.azs[count.index]}"
  count             = "${length(var.private_subnets)}"

  tags {
    Name = "${var.name}-private"
  }
}

resource "aws_subnet" "public" {
  provider          = "${var.provider}"
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "${var.public_subnets[count.index]}"
  availability_zone = "${var.azs[count.index]}"
  count             = "${length(var.public_subnets)}"

  tags {
    Name = "${var.name}-public"
  }

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "private" {
  provider       = "${var.provider}"
  count          = "${length(var.private_subnets)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "public" {
  provider       = "${var.provider}"
  count          = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

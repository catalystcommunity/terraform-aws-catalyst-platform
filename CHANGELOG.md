## [1.3.3](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.3.2...v1.3.3) (2023-03-07)


### Bug Fixes

* Add role name and id to the outputs ([#20](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/20)) ([9c1f6e7](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/9c1f6e71a58017c867f291d58783bf760056a327))

## [1.3.2](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.3.1...v1.3.2) (2022-10-03)


### Bug Fixes

* add network resource id outputs ([#18](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/18)) ([3335174](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/3335174037dff373aa0318e6f5a06e917be28e9a))

## [1.3.1](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.3.0...v1.3.1) (2022-07-19)


### Bug Fixes

* alarm action sns topic reference ([#17](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/17)) ([3bf3797](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/3bf379736aecc5eded99385dad730e281d45ece2))

# [1.3.0](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.2.0...v1.3.0) (2022-07-19)


### Features

* add sns topics and alert lambda functions for synthetic canaries ([#16](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/16)) ([b480340](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/b480340f40269b44be73c75d610bbbe6a68d2dfd))

# [1.2.0](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.7...v1.2.0) (2022-07-15)


### Features

* add cloudwatch synthetics functionality ([#15](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/15)) ([897cdcd](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/897cdcdd6d3fede98e4311a72bc338102c109425))

## [1.1.7](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.6...v1.1.7) (2022-07-08)


### Bug Fixes

* set create_before_destroy on nodegroups ([#14](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/14)) ([1654868](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/1654868a742b8d77de35d9517287596c0ac0dff4))

## [1.1.6](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.5...v1.1.6) (2022-07-07)


### Bug Fixes

* Added outputs for eks cluster name, eks cluster arn, and eks irs… ([#11](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/11)) ([1acc68c](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/1acc68c4634a28fe453fb01b6fda89d475bc464e))

## [1.1.5](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.4...v1.1.5) (2022-06-16)


### Bug Fixes

* loki and cortex s3 policy ([#10](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/10)) ([869f481](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/869f48124496427cd0f16979b42fdd85ecb48d43))

## [1.1.4](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.3...v1.1.4) (2022-06-16)


### Bug Fixes

* bucket name reference in policy documents ([#9](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/9)) ([9db63d7](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/9db63d7ae760bea5b853cda7d596ac601ae4053d))

## [1.1.3](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.2...v1.1.3) (2022-06-16)


### Bug Fixes

* allow for disabling observability bucket creation ([#8](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/8)) ([98ca7ae](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/98ca7ae14f7beebc6cdfeb9e3cdf26d42dec6652))

## [1.1.2](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.1...v1.1.2) (2022-06-15)


### Bug Fixes

* add depends on to igw on public subnets ([#7](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/7)) ([d8dedda](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/d8dedda574e17e5bbe14541cc44bb83da30c19d5))

## [1.1.1](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.1.0...v1.1.1) (2022-06-14)


### Bug Fixes

* use replace function to remove path from sso role arns ([#6](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/6)) ([c231fa6](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/c231fa6688bb5e1bcdaeb03d5c8112d122a5a709))

# [1.1.0](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.0.1...v1.1.0) (2022-06-08)


### Features

* allow for overriding velero bucket name, make bucket optional ([#4](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/4)) ([bd151e0](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/bd151e0ebbf3204426041c51bbdf0aba820913f5))

## [1.0.1](https://github.com/catalystsquad/terraform-aws-catalyst-platform/compare/v1.0.0...v1.0.1) (2022-06-06)


### Bug Fixes

* **docs:** add automatic doc generation, initial readme, gitignore ([#2](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/2)) ([edc4ce8](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/edc4ce8a26569a969f59dda075a39035d367acb8))

# 1.0.0 (2022-06-03)


### Features

* initial aws platform module, semantic release workflows ([#1](https://github.com/catalystsquad/terraform-aws-catalyst-platform/issues/1)) ([e1da28d](https://github.com/catalystsquad/terraform-aws-catalyst-platform/commit/e1da28d9d0e0716d19575313267076c5d8d30bcc))

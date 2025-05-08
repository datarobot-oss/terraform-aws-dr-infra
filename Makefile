.PHONY: providers modules charts


airgap-package: providers modules charts


providers_dir := airgap-package/terraform.d/plugins

providers:
	@echo "Copying providers into ${providers_dir}..."
	@mkdir -p ${providers_dir}
	terraform init; \
	terraform providers mirror ${providers_dir}; \
	rm -rf .terraform .terraform.lock.hcl


# name,source
terraform_aws_modules := \
terraform-aws-acm,terraform-aws-modules/acm/aws \
terraform-aws-ecr,terraform-aws-modules/ecr/aws \
terraform-aws-eks,terraform-aws-modules/eks/aws \
terraform-aws-eks-pod-identity,terraform-aws-modules/eks-pod-identity/aws \
terraform-aws-iam,terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc \
terraform-aws-kms,terraform-aws-modules/kms/aws \
terraform-aws-route53,terraform-aws-modules/route53/aws//modules/zones \
terraform-aws-s3-bucket,terraform-aws-modules/s3-bucket/aws \
terraform-aws-vpc,terraform-aws-modules/vpc/aws

modules_dir := airgap-package/terraform.d/modules

modules:
	@echo "Copying modules into ${modules_dir}..."
	@mkdir -p ${modules_dir}
	@git clone --depth 1 https://github.com/datarobot-oss/terraform-aws-dr-infra ${modules_dir}/terraform-aws-dr-infra
	@sed -E -i "" "/^ *version +=/d" ${modules_dir}/terraform-aws-dr-infra/main.tf
	@for module in ${terraform_aws_modules}; do \
		module_name=$$(echo $$module | cut -d, -f1); \
		module_source=$$(echo $$module | cut -d, -f2); \
		git clone --depth 1 https://github.com/terraform-aws-modules/$$module_name ${modules_dir}/$$module_name; \
		sed -i "" "s|$$module_source|${modules_dir}/$$module_name|g" ${modules_dir}/terraform-aws-dr-infra/main.tf; \
	done


# repo_url,repo_name,chart_name
helm_charts := \
https://aws.github.io/eks-charts,eks-charts,aws-load-balancer-controller \
https://charts.jetstack.io,cert-manager,cert-manager \
https://kubernetes.github.io/autoscaler,cluster-autoscaler,cluster-autoscaler \
https://kubernetes-sigs.github.io/descheduler,descheduler,descheduler \
https://kubernetes-sigs.github.io/aws-ebs-csi-driver,aws-ebs-csi-driver,aws-ebs-csi-driver \
https://charts.bitnami.com/bitnami,external-dns,external-dns \
https://kubernetes.github.io/ingress-nginx,ingress-nginx,ingress-nginx \
https://kubernetes-sigs.github.io/metrics-server,metrics-server,metrics-server \
https://nvidia.github.io/k8s-device-plugin,nvidia-device-plugin,nvidia-device-plugin

charts_dir := airgap-package/terraform.d/charts

charts:
	@echo "Copying helm charts into ${charts_dir}..."
	@mkdir -p ${charts_dir}
	@for helm_repo in ${helm_charts}; do \
		repo_url=$$(echo $$helm_repo | cut -d, -f1); \
		repo_name=$$(echo $$helm_repo | cut -d, -f2); \
		chart_name=$$(echo $$helm_repo | cut -d, -f3); \
		helm repo add $$repo_name $$repo_url; \
		helm pull $$repo_name/$$chart_name -d ${charts_dir}; \
	done

clean:
	rm -rf airgap-package

clean-helm:
	@for helm_repo in ${helm_charts}; do \
		repo_name=$$(echo $$helm_repo | cut -d, -f2); \
		helm repo remove $$repo_name; \
	done

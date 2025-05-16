.PHONY: bundle providers modules charts

working_dir := $(shell pwd)

bundle_name := terraform-aws-dr-infra.tgz
bundle_dir := ${working_dir}/bundle
bundle: providers modules charts
	cp -R ${working_dir}/examples/airgap/* ${bundle_dir}

	# Update source of terraform-aws-dr-infra module
	sed -i "" "s|source = \"../..\"|source = \"./modules/terraform-aws-dr-infra\"|" ${bundle_dir}/main.tf

	# Update source of terraform-aws-eks module and remove version
	sed -E -i "" -e "s|terraform-aws-modules/eks/aws/|./modules/terraform-aws-eks|" -e "/^ *version +=/d" ${bundle_dir}/main.tf

	# Archive and zip bundle
	@tar -czf ${bundle_name} -C ${bundle_dir} .


providers_dir := ${bundle_dir}/terraform.d/plugins
providers:
	@echo "Copying providers into ${providers_dir}..."
	@mkdir -p ${providers_dir}
	@cd ${working_dir}/examples/airgap; \
	terraform init -reconfigure -upgrade; \
terraform providers mirror --platform=linux_amd64 ${providers_dir}; \
	rm -rf .terraform .terraform.lock.hcl; \
	cd ${working_dir}


# name,source
terraform_aws_modules := \
terraform-aws-acm,terraform-aws-modules/acm/aws \
terraform-aws-ecr,terraform-aws-modules/ecr/aws \
terraform-aws-eks,terraform-aws-modules/eks/aws \
terraform-aws-eks-pod-identity,terraform-aws-modules/eks-pod-identity/aws \
terraform-aws-iam,terraform-aws-modules/iam/aws \
terraform-aws-kms,terraform-aws-modules/kms/aws \
terraform-aws-route53,terraform-aws-modules/route53/aws \
terraform-aws-s3-bucket,terraform-aws-modules/s3-bucket/aws \
terraform-aws-vpc,terraform-aws-modules/vpc/aws

modules_dir := ${bundle_dir}/modules

modules:
	@echo "Copying modules into ${modules_dir}..."
	@mkdir -p ${modules_dir}

	# Copy local terraform-aws-dr-infra module
	@mkdir -p ${modules_dir}/terraform-aws-dr-infra
	@cp -R main.tf variables.tf versions.tf outputs.tf modules ${modules_dir}/terraform-aws-dr-infra

	# Replace eks-pod-identity remote source in terraform-aws-dr-infra sub modules
	find ${modules_dir}/terraform-aws-dr-infra/modules -type f -name main.tf -exec sed -i "" "s|terraform-aws-modules/eks-pod-identity/aws|../../../terraform-aws-eks-pod-identity|g" {} \;

	# Remove module source version lines from terraform-aws-dr-infra
	find ${modules_dir}/terraform-aws-dr-infra -type f -name main.tf -exec sed -E -i "" "/^ *version +=/d" {} \;

	# Clone each AWS module and replace the remote source with local source
	@for module in ${terraform_aws_modules}; do \
		module_name=$$(echo $$module | cut -d, -f1); \
		module_source=$$(echo $$module | cut -d, -f2); \
		git clone --depth 1 https://github.com/terraform-aws-modules/$$module_name ${modules_dir}/$$module_name; \
		sed -E -i "" "s|$$module_source/?|../$$module_name|g" ${modules_dir}/terraform-aws-dr-infra/main.tf; \
	done

	# Update source of terraform-aws-kms module in terraform-aws-eks and remove version
	sed -E -i "" -e "s|terraform-aws-modules/kms/aws|../terraform-aws-kms|g" -e "/^ *version =/d" ${modules_dir}/terraform-aws-eks/main.tf


# repo_url,repo_name,chart_name,chart_version
helm_charts := \
https://aws.github.io/eks-charts,eks-charts,aws-load-balancer-controller,1.10.0 \
https://charts.jetstack.io,cert-manager,cert-manager,1.16.1 \
https://kubernetes.github.io/autoscaler,cluster-autoscaler,cluster-autoscaler,9.43.2 \
https://kubernetes-sigs.github.io/descheduler,descheduler,descheduler,0.31.0 \
https://kubernetes-sigs.github.io/aws-ebs-csi-driver,aws-ebs-csi-driver,aws-ebs-csi-driver,2.37.0 \
https://charts.bitnami.com/bitnami,external-dns,external-dns,8.5.1 \
https://kubernetes.github.io/ingress-nginx,ingress-nginx,ingress-nginx,4.11.5 \
https://kubernetes-sigs.github.io/metrics-server,metrics-server,metrics-server,3.12.1 \
https://nvidia.github.io/k8s-device-plugin,nvidia-device-plugin,nvidia-device-plugin,0.17.0

charts_dir := ${bundle_dir}/charts

charts: modules
	@echo "Copying helm charts into ${charts_dir}..."
	@mkdir -p ${charts_dir}

	# Pull helm charts and update remote sources to local paths
	@for helm_repo in ${helm_charts}; do \
		repo_url=$$(echo $$helm_repo | cut -d, -f1); \
		repo_name=$$(echo $$helm_repo | cut -d, -f2); \
		chart_name=$$(echo $$helm_repo | cut -d, -f3); \
		chart_version=$$(echo $$helm_repo | cut -d, -f4); \
		helm repo add $$repo_name $$repo_url; \
		helm pull $$repo_name/$$chart_name --version "$$chart_version" -d ${charts_dir}; \
		sed -E -i "" -e "/^ *version +=/d" -e "/^ *repository +=/d" -e "s|^ *chart += \"$$chart_name\"|  chart = \"../../../../charts/$$chart_name-$$chart_version.tgz\"|" ${modules_dir}/terraform-aws-dr-infra/modules/$$chart_name/main.tf; \
	done


clean:
	rm -rf ${bundle_dir}
	rm ${bundle_name}


clean-helm:
	@for helm_repo in ${helm_charts}; do \
		repo_name=$$(echo $$helm_repo | cut -d, -f2); \
		helm repo remove $$repo_name; \
	done

# Bootstrapping Lambda deployment (manual / pre-CI)

This document explains how to bootstrap lambda function packaging and deployment before CI/CD is connected.

Overview:

- The infrastructure expects two lambda deployment packages:
  - `record-service-lambda.zip`
  - `text-service-lambda.zip`

Paths:

- By default the lambda module looks for packages at: `infras/../build/record-service-lambda.zip` and `infras/../build/text-service-lambda.zip` (i.e. repo-root `./build/`).

Options for bootstrapping:

1. Local-first (quick):

   - Build the packages and place them in `./build/`.
   - Run Terraform as usual: `terraform apply` will pick up `filename` packages and create/update Lambdas.

2. S3-driven (recommended if you want a single source for artifacts):

   - Create the CodePipeline artifacts bucket (this repo's CodePipeline module creates the bucket named `${var.project_name}-${var.environment}-pipeline-artifacts`).
     You can create the bucket alone with Terraform by running:

     terraform apply -target=module.codepipeline

   - Upload your packages to the bucket (`s3://<project>-<env>-pipeline-artifacts/record-service-lambda.zip` and `text-service-lambda.zip`).
     The helper script at `scripts/bootstrap/package-lambdas.sh` can upload for you:

     ./scripts/bootstrap/package-lambdas.sh upload <project>-<env>-pipeline-artifacts

   - When packages are present in the bucket, enable S3 mode for the lambda module by passing variables to the module or via TF_VARs:

     - `record_use_s3 = true`
     - `record_service_s3_bucket = "<project>-<env>-pipeline-artifacts"`
     - `record_service_s3_key = "record-service-lambda.zip"`

     - `text_use_s3 = true`
     - `text_service_s3_bucket = "<project>-<env>-pipeline-artifacts"`
     - `text_service_s3_key = "text-service-lambda.zip"`

   - Important: because codepipeline and the lambda module reference each other in some usage scenarios, do these steps in order to avoid dependency cycles:
     1. Apply `module.codepipeline` (create bucket)
     2. Upload packages to the bucket
     3. Apply `module.lambda` with `*_use_s3 = true`

3. CI/CD later

   - After bootstrapping with either local or S3, you can enable CodeBuild / CodePipeline to publish artifacts automatically.

4. Shortcut: helper wrapper script (safe guided flow)

   We've added a convenience wrapper that runs the recommended sequence for you — create the artifacts bucket, package local zips, upload them, and apply the lambda module.

   From repo root run:

   ./scripts/bootstrap/terraform-lambda-bootstrap.sh --auto-approve

   The script reads defaults from `infras/dev.auto.tfvars` if present and uploads built artifacts to `<project>-<env>-pipeline-artifacts`.

## Helpful commands

- Create zips only:
  ./scripts/bootstrap/package-lambdas.sh

- Create zips and upload to bucket:
  ./scripts/bootstrap/package-lambdas.sh upload <project>-<env>-pipeline-artifacts

- Use the guided terraform wrapper (create bucket -> package -> upload -> apply lambdas):
  ./scripts/bootstrap/terraform-lambda-bootstrap.sh --auto-approve

## Notes

- The packaging script performs a simple recursive zip of the service directories. For node services you may want to run a build step (e.g. `npm ci && npm run build`) prior to packaging so the `dist/` output is included in the zip.
- Recent helper improvements additionally attempt safe local builds when possible:
  - For NodeJS services with a `package.json` and an available `npm`, the packaging script will try `npm ci --production` followed by `npm run build` (if present) inside a temporary staging directory before creating the ZIP.
  - For Python services with `requirements.txt` and a `pip` available, the script will `pip install -r requirements.txt --target <staging>` to include runtime dependencies in the zip.
  - These build steps are best-effort and non-fatal — if build tools aren't available the script falls back to zipping repository files as-is. This avoids modifying the source tree while still producing Lambda-ready artifacts when possible.
- Keep an eye on function runtime/handler configuration when packaging — node lambda expects `dist/lambda.handler`, python uses `lambda_handler.handler` here.

## CodeBuild support

The repository includes `buildspec.yml` files in `services/record-service` and `services/text-service`. These CodeBuild buildspecs:

- Build the service (if applicable)
- Create a lambda-friendly ZIP
- Upload the artifact to the pipeline artifacts bucket using the `ARTIFACTS_BUCKET` environment variable set by the CodeBuild project

To enable these CodeBuild projects using Terraform, toggle the feature flags in `infras/main.tf` under `module.codebuild` (set `create_record_service_build` and/or `create_text_service_build` to `true`) and ensure `module.codepipeline` (the artifacts bucket) is created.

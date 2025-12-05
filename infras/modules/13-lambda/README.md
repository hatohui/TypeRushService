# Lambda module (infras/modules/13-lambda)

This module manages the Record and Text Lambda functions.

Supported deploy modes

- Local packaging: Put ZIP files into the repository `build/` directory (default paths) and Terraform will use the `filename` attribute.
- S3 packaging: Set `*_use_s3 = true` and specify `*_s3_bucket` and `*_s3_key` to deploy code directly from S3.

Bootstrapping notes

- If you want to enable S3-based deployment without a running CI system, first create the artifacts bucket (module.codepipeline) and upload the zip files (see `infras/BOOTSTRAP_LAMBDAS.md`).
- Recommended sequence to avoid cycles:
  1. terraform apply -target=module.codepipeline
  2. Upload artifacts to the bucket
  3. terraform apply -target=module.lambda (or set `*_use_s3` variables and run a full apply)

When integrating CI/CD later, the pipeline will upload artifacts into the same artifacts bucket and you can flip on the `*_use_s3` flags or let CodePipeline manage Lambda updates.

## CodeBuild buildspecs

This repository includes `services/record-service/buildspec.yml` and `services/text-service/buildspec.yml` that create ZIP artifacts and upload them to the pipeline artifacts bucket (`<project>-<env>-pipeline-artifacts`). When you enable CodeBuild projects (via `module.codebuild`) they will use the `ARTIFACTS_BUCKET` environment variable to perform uploads.

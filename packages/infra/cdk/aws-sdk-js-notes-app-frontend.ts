import { App, Tags } from "aws-cdk-lib";
import { AwsSdkJsNotesAppFrontendStack } from "./aws-sdk-js-notes-app-frontend-stack";

const app = new App();
const awsSdkJsNotesAppFrontendStack = new AwsSdkJsNotesAppFrontendStack(
  app,
  "aws-sdk-js-notes-app-frontend"
);
Tags.of(awsSdkJsNotesAppFrontendStack).add(
  "aws-apn-id",
  "pc:9yq38ki5jw5mas7jhjthpgveo"
);

import { App, Tags } from "aws-cdk-lib";
import { AwsSdkJsNotesAppStack } from "./aws-sdk-js-notes-app-stack";

const app = new App();
const awsSdkJsNotesAppStack = new AwsSdkJsNotesAppStack(
  app,
  "aws-sdk-js-notes-app"
);
Tags.of(awsSdkJsNotesAppStack).add(
  "aws-apn-id",
  "pc:9yq38ki5jw5mas7jhjthpgveo"
);

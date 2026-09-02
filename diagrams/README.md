# Architecture diagrams

These diagrams use [Mermaid](https://mermaid.js.org/), so they can be kept next
to the Terraform and reviewed as text.

## Preview in VS Code

1. Install an extension that previews Mermaid files, such as **Mermaid Preview**.
2. Open any `.mmd` file in this directory.
3. Open the Command Palette and run **Mermaid: Preview**.

Alternatively, VS Code's built-in Markdown preview can render Mermaid code blocks.
Open this README and select **Markdown: Open Preview to the Side**.

## Diagrams

- [AWS architecture](./aws-architecture.mmd) shows where each resource sits and
  how network traffic moves through the stack.
- [Request flow](./request-flow.mmd) follows one browser request through
  WordPress and its backing services.
- [Terraform dependencies](./terraform-dependencies.mmd) shows the main resource
  creation dependencies represented by `main.tf`.
- [Public/private networking walkthrough](../docs/public-private-networking.md)
  explains the subnet routes and request path step by step.

The AWS architecture source is kept in one place to prevent the documentation
from drifting. Open [aws-architecture.mmd](./aws-architecture.mmd) to preview it.

Dashed cache connections indicate intended application traffic: Terraform
provisions Valkey and the PHP Redis extension, but `main.tf` does not yet
configure WordPress to use the cache endpoint.

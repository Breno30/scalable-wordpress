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

- [Request flow](./request-flow.mmd) follows one browser request through
  WordPress, its configured Valkey object cache, RDS, and EFS. The rendered
  [SVG](./request-flow.svg) is embedded in the repository README.
- [Public/private networking walkthrough](../docs/public-private-networking.md)
  explains the subnet routes and request path step by step.

The bootstrap script installs and activates the Redis Object Cache plugin,
configures its Valkey endpoint and TLS connection, and installs its object-cache
drop-in. The dashed arrows in the sequence diagram represent responses rather
than unconfigured traffic.

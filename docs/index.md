# Application package data flow patterns

Earth Observation (EO) workflows often involve repeatedly implementing a handful of core behaviors: how input data (e.g., satellite scenes) are retrieved into the container, how algorithms process them, and how results are published to cloud storage or catalog systems. While the specific algorithms and processing logic vary widely, these **stage‑in** and **stage‑out** patterns remain remarkably consistent across projects.

The **Application Package Patterns** project provides a curated collection of **CWL** (Common Workflow Language) templates capturing these recurring data handling workflows. Developed as in the context of the Earth Observation Exploitation Platform Common Architecture ([EOEPCA](https://eoepca.org/)) spearheaded by ESA, these patterns serve multiple critical purposes:

 * Simplification & Reuse: By standardizing common data ingestion and output-handling behaviors, developers can focus on implementing the unique logic of their EO algorithms—without reinventing the boilerplate for file staging or publishing.
* Portability & Interoperability: Aligning with the OGC Best Practice for EO Application Packages, this approach supports seamless deployment across diverse platforms. These patterns enable your workflows to run unmodified on local machines, HPC clusters, Kubernetes, or cloud-native infrastructures
 * Ease of Verification & Automation: The CWL templates are designed to be machine-validated and easily orchestrated—making it straightforward to set up automatic testing, CI pipelines, or deployments. You can verify behavior quickly, ensuring robust and repeatable results


## What You'll Find in This Repository

This module contains end-to-end, ready-to-use CWL workflows representing canonical EO data flow scenarios:

 * Stage‑in templates (stage‑in.cwl, stage‑in-file.cwl)
 * Stage‑out template (stage‑out.cwl)
 * Orchestrator workflows for each pattern (e.g., pattern-1.cwl, pattern-2.cwl, etc.) that wire input staging, your algorithm CWL, and output publishing together

Each pattern defines:

* The input signature (e.g., one Directory, a stack of directories, two scenes, etc.)
* The output signature (e.g., a Directory, multiple directories, JSON or scalar outputs)
* The logic to insert stage‑in and stage‑out nodes—transforming local Directory references into remote-compatible URI formats for robust, cloud-native execution

## Why It Matters

Creating EO workflows that are portable, reproducible, and platform-agnostic can be challenging. With these patterns:

 * Researchers and developers save time by plugging in your algorithm CWL into proven, battle-tested I/O scaffolding.
 * Operations teams benefit from repeatable deployments to platforms that understand these standardized patterns and can orchestrate CWL workflows accordingly.
 * The entire EO community reaps the reward of shared, interoperable infrastructure, following the FAIR principles and the OGC Earth Observation Application Package best practices

## Further Reading 

 * [OGC Best Practice for Earth Observation Application Package](https://docs.ogc.org/bp/20-089r1.html)
 * [Getting started on Earth Observation Application Packaging with CWL](https://eoap.github.io/quickwin/)
 * [Building Open Resources for Earth Observation Application Packages](https://discuss.terradue.com/t/1271)



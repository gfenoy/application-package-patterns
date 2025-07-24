cwlVersion: v1.2
$namespaces:
  s: https://schema.org/

schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf

s:softwareVersion: 1.0.0

$graph:
  - id: echo-workflow
    class: Workflow
    label: Echo All CWL Primitive Types
    doc: This workflow demonstrates usage of all CWL primitive types. It runs the `echo-tool` with default values and captures the output in a file.

    inputs:
    - id: null_input
      type: ["null", "string"]
      label: Nullable Input
      doc: A nullable input that can be null or a string
      default: null
    - id: boolean_input
      type: boolean
      label: Boolean Input
      doc: A boolean value
      default: true
    - id: int_input 
      type: int
      label: Integer Input
      doc: An integer value
      default: 42
    - id: long_input
      type: long
      label: Long Input
      doc: A long integer value
      default: 1234567890123
    - id: float_input
      type: float
      label: Float Input
      doc: A floating-point number
      default: 3.14
    - id: double_input
      type: double
      label: Double Input
      doc: A double-precision float
      default: 2.7182818284
    - id: string_input
      type: string
      label: String Input
      doc: A string input
      default: "Hello, CWL!"

    outputs:
      - id: echoed_values
        type: string
        outputSource: 
        - echo_step/echoed
        label: Echoed Values
        doc: The string containing echoed primitive values

    steps:
      echo_step:
        run: "#echo-tool"
        in: {}
        out:
        - echoed

  - id: echo-tool
    class: CommandLineTool
    label: Echo Primitive Types Tool
    doc: A tool that echoes all primitive CWL types null, boolean, int, long, float, double, and string. The values are written to a file called `echoed.txt`.

    requirements:
      InlineJavascriptRequirement: {}
      EnvVarRequirement:
        envDef:
          PATH: $PATH:/app/envs/vegetation-index/bin
      ResourceRequirement:
        coresMax: 1
        ramMax: 256
    
      DockerRequirement:
        dockerPull: docker.io/library/vegetation-indexes:latest

    baseCommand: [bash, -c]
    arguments:
      - |
        echo "$0 $1 $2 $3 $4 $5 $6"

    inputs:
      null_input:
        type: ["null", "string"]
        inputBinding:
          position: 0
        doc: A nullable input (null or string)
        default: null

      boolean_input:
        type: boolean
        inputBinding:
          position: 1
        doc: A boolean value
        default: true

      int_input:
        type: int
        inputBinding:
          position: 2
        doc: An integer value
        default: 42

      long_input:
        type: long
        inputBinding:
          position: 3
        doc: A long integer
        default: 1234567890123

      float_input:
        type: float
        inputBinding:
          position: 4
        doc: A floating-point number
        default: 3.14

      double_input:
        type: double
        inputBinding:
          position: 5
        doc: A double-precision float
        default: 2.7182818284

      string_input:
        type: string
        inputBinding:
          position: 6
        doc: A string input
        default: "Hello, CWL!"

    stdout: message
    outputs:
      echoed:
        outputBinding:
          glob: message
          loadContents: true
          outputEval: $(self[0].contents)
        type: string

  
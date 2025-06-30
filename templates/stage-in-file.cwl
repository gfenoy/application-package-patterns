cwlVersion: v1.0

class: CommandLineTool
id: my-asthonishing-stage-in

inputs:
  reference:
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    doc: "An URL to stage" 
    label: "Reference URL"
  another_input:
    type: string
    doc: "An additional input for demonstration purposes"
    label: "Another Input"
outputs:
  staged:
    type: File
    outputBinding:
      glob: staged
baseCommand: 
- python
- stage.py
arguments:
- $( inputs.reference.value )
- $( inputs.another_input ) # This is an additional input to demonstrate the use of multiple inputs
requirements:
  SchemaDefRequirement:
    types:
    - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
  DockerRequirement:
    dockerPull: ghcr.io/eoap/dask-app-package/cloudless-mosaic:1.0.1
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: stage.py
        entry: |-
          import requests
          import planetary_computer

          href = sys.argv[1]

          signed_url = planetary_computer.sign(href)
          output_path = "staged"

          response = requests.get(signed_url, stream=True)
          response.raise_for_status()  # Raise an error for bad status codes

          with open(output_path, "wb") as f:
              for chunk in response.iter_content(chunk_size=8192):
                  f.write(chunk)

          print(f"Downloaded to {output_path}")

          empty_arg = sys.argv[2]
          
          


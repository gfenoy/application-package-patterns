cwlVersion: v1.0

class: CommandLineTool
id: my-asthonishing-stage-in

inputs:
  reference:
    type: https://raw.githubusercontent.com/eoap/schemas/main/url.yaml#URL
    doc: "A STAC Item to stage" 
    label: "STAC Item URL"
  another_input:
    type: string
    doc: "An additional input for demonstration purposes"
    label: "Another Input"
outputs:
  staged:
    type: Directory
    outputBinding:
      glob: .
baseCommand: 
- python
- stage.py
arguments:
- $( inputs.reference )
- $( inputs.another_input ) # This is an additional input to demonstrate the use of multiple inputs
requirements:
  SchemaDefRequirement:
    types:
    - $import: https://raw.githubusercontent.com/eoap/schemas/main/url.yaml
  DockerRequirement:
    dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.0.0
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: stage.py
        entry: |-
          import pystac
          import stac_asset
          import asyncio
          import os
          import sys

          config = stac_asset.Config(warn=True)

          async def main(href: str):
              
              item = pystac.read_file(href)
              
              os.makedirs(item.id, exist_ok=True)
              cwd = os.getcwd()
              
              os.chdir(item.id)
              item = await stac_asset.download_item(item=item, directory=".", config=config)
              os.chdir(cwd)
              
              cat = pystac.Catalog(
                  id="catalog",
                  description=f"catalog with staged {item.id}",
                  title=f"catalog with staged {item.id}",
              )
              cat.add_item(item)
              
              cat.normalize_hrefs("./")
              cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)

              return cat

          href = sys.argv[1]

          cat = asyncio.run(main(href))



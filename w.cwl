$graph:
- $namespaces:
    cwltool: http://commonwl.org/cwltool#
  class: Workflow
  doc: Wrapped workflow with required stage-in and stage-out steps
  hints:
    cwltool:Secrets:
      secrets: []
  id: main
  inputs:
    aoi:
      doc: area of interest as a bounding box
      id: aoi
      label: area of interest
      type: string
    aws_access_key_id:
      type: string
    aws_secret_access_key:
      type: string
    bands:
      default:
      - green
      - nir08
      doc: bands used for the NDWI
      id: bands
      label: bands used for the NDWI
      type: string[]
    endpoint_url:
      type: string
    epsg:
      default: EPSG:4326
      doc: EPSG code
      id: epsg
      label: EPSG code
      type: string
    item_1:
      doc: Reference to a STAC item
      id: item_1
      label: STAC item reference
      type: string
    item_2:
      doc: Optional reference to a STAC item
      id: item_2
      label: Optional STAC item reference
      type: string?
    region_name:
      type: string
    s3_bucket:
      type: string
    sub_path:
      type: string
  label: Wrapped workflow
  outputs:
    stac_catalog:
      outputSource:
      - node_stage_out/stac_catalog_out
      type: string
  requirements:
    ScatterFeatureRequirement: {}
    SubworkflowFeatureRequirement: {}
  steps:
    node_stage_in:
      in:
        input: item_1
      out:
      - item_1_out
      run:
        arguments:
        - $( inputs.input )
        baseCommand:
        - python
        - stage.py
        class: CommandLineTool
        cwlVersion: v1.0
        id: main
        inputs:
          input:
            type: string?
        outputs:
          item_1_out:
            outputBinding:
              glob: .
            type: Directory
        requirements:
          DockerRequirement:
            dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.1.0
          InitialWorkDirRequirement:
            listing:
            - entry: "import pystac\nimport stac_asset\nimport asyncio\nimport os\n\
                import sys\nfrom loguru import logger\n\nconfig = stac_asset.Config(warn=True)\n\
                \nasync def main(href: str):\n    \n    item = pystac.read_file(href)\n\
                \    \n    os.makedirs(item.id, exist_ok=True)\n    cwd = os.getcwd()\n\
                \    \n    os.chdir(item.id)\n    item = await stac_asset.download_item(item=item,\
                \ directory=\".\", config=config)\n    os.chdir(cwd)\n    \n    cat\
                \ = pystac.Catalog(\n        id=\"catalog\",\n        description=f\"\
                catalog with staged {item.id}\",\n        title=f\"catalog with staged\
                \ {item.id}\",\n    )\n    cat.add_item(item)\n    \n    cat.normalize_hrefs(\"\
                ./\")\n    cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)\n\
                \n    return cat\n\nhref = sys.argv[1]\nlogger.info(f\"Staging {href}\"\
                )\ncat = asyncio.run(main(href))\nlogger.info(f\"Staged {href} to\
                \ {cat.get_self_href()}\")"
              entryname: stage.py
          InlineJavascriptRequirement: {}
    node_stage_in_1:
      in:
        input: item_2
      out:
      - item_2_out
      run:
        arguments:
        - $( inputs.input )
        baseCommand:
        - python
        - stage.py
        class: CommandLineTool
        cwlVersion: v1.0
        id: main
        inputs:
          input:
            type: string?
        outputs:
          item_2_out: ''
        requirements:
          DockerRequirement:
            dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.1.0
          InitialWorkDirRequirement:
            listing:
            - entry: "import pystac\nimport stac_asset\nimport asyncio\nimport os\n\
                import sys\nfrom loguru import logger\n\nconfig = stac_asset.Config(warn=True)\n\
                \nasync def main(href: str):\n    \n    item = pystac.read_file(href)\n\
                \    \n    os.makedirs(item.id, exist_ok=True)\n    cwd = os.getcwd()\n\
                \    \n    os.chdir(item.id)\n    item = await stac_asset.download_item(item=item,\
                \ directory=\".\", config=config)\n    os.chdir(cwd)\n    \n    cat\
                \ = pystac.Catalog(\n        id=\"catalog\",\n        description=f\"\
                catalog with staged {item.id}\",\n        title=f\"catalog with staged\
                \ {item.id}\",\n    )\n    cat.add_item(item)\n    \n    cat.normalize_hrefs(\"\
                ./\")\n    cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)\n\
                \n    return cat\n\nhref = sys.argv[1]\nlogger.info(f\"Staging {href}\"\
                )\ncat = asyncio.run(main(href))\nlogger.info(f\"Staged {href} to\
                \ {cat.get_self_href()}\")"
              entryname: stage.py
          InlineJavascriptRequirement: {}
    node_stage_out:
      in:
        aws_access_key_id: aws_access_key_id
        aws_secret_access_key: aws_secret_access_key
        endpoint_url: endpoint_url
        region_name: region_name
        s3_bucket: s3_bucket
        sub_path: sub_path
        wf_outputs: on_stage/stac_catalog
      out:
      - stac_catalog_out
      run:
        arguments:
        - $( inputs.wf_outputs.path )
        - $( inputs.s3_bucket )
        - $( inputs.sub_path )
        baseCommand:
        - python
        - stage.py
        class: CommandLineTool
        cwlVersion: v1.0
        doc: Stage-out the results to S3
        id: stage-out
        inputs:
          aws_access_key_id:
            type: string
          aws_secret_access_key:
            type: string
          endpoint_url:
            type: string
          region_name:
            type: string
          s3_bucket:
            type: string
          sub_path:
            type: string
          wf_outputs:
            type: Directory
        outputs:
          stac_catalog_out:
            outputBinding:
              glob: message
              loadContents: true
              outputEval: $( self[0].contents )
            type: string
        requirements:
          DockerRequirement:
            dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.1.0
          EnvVarRequirement:
            envDef:
              aws_access_key_id: $( inputs.aws_access_key_id )
              aws_endpoint_url: $( inputs.endpoint_url )
              aws_region_name: $( inputs.region_name )
              aws_secret_access_key: $( inputs.aws_secret_access_key )
          InitialWorkDirRequirement:
            listing:
            - entry: "import os\nimport sys\nimport pystac\nimport botocore\nimport\
                \ boto3\nimport shutil\nimport uuid\nfrom loguru import logger\nfrom\
                \ pystac.stac_io import DefaultStacIO, StacIO\nfrom urllib.parse import\
                \ urlparse\nfrom datetime import datetime\nfrom pystac.extensions.item_assets\
                \ import ItemAssetsExtension, AssetDefinition\n\ncat_url = sys.argv[1]\n\
                bucket = sys.argv[2]\nuid = str(uuid.uuid4()).replace(\"-\", \"\"\
                )[:6]\nsubfolder = f\"{sys.argv[3]}-{uid}\"\n\naws_access_key_id =\
                \ os.environ[\"aws_access_key_id\"]\naws_secret_access_key = os.environ[\"\
                aws_secret_access_key\"]\nregion_name = os.environ[\"aws_region_name\"\
                ]\nendpoint_url = os.environ[\"aws_endpoint_url\"]\n\nlogger.info(f\"\
                stage-out {cat_url} to s3://{bucket}/{subfolder}\")\n\nshutil.copytree(cat_url,\
                \ \"/tmp/catalog\")\ncat = pystac.read_file(os.path.join(\"/tmp/catalog\"\
                , \"catalog.json\"))\n\nlogger.info(f\"catalog {cat}\")\n\nclass CustomStacIO(DefaultStacIO):\n\
                \    \"\"\"Custom STAC IO class that uses boto3 to read from S3.\"\
                \"\"\n\n    def __init__(self):\n        self.session = botocore.session.Session()\n\
                \        self.s3_client = self.session.create_client(\n          \
                \  service_name=\"s3\",\n            use_ssl=True,\n            aws_access_key_id=aws_access_key_id,\n\
                \            aws_secret_access_key=aws_secret_access_key,\n      \
                \      endpoint_url=endpoint_url,\n            region_name=region_name,\n\
                \        )\n\n    def write_text(self, dest, txt, *args, **kwargs):\n\
                \        parsed = urlparse(dest)\n        if parsed.scheme == \"s3\"\
                :\n            self.s3_client.put_object(\n                Body=txt.encode(\"\
                UTF-8\"),\n                Bucket=parsed.netloc,\n               \
                \ Key=parsed.path[1:],\n                ContentType=\"application/geo+json\"\
                ,\n            )\n        else:\n            super().write_text(dest,\
                \ txt, *args, **kwargs)\n\n\nclient = boto3.client(\n    \"s3\",\n\
                \    aws_access_key_id=aws_access_key_id,\n    aws_secret_access_key=aws_secret_access_key,\n\
                \    endpoint_url=endpoint_url,\n    region_name=region_name,\n)\n\
                \nStacIO.set_default(CustomStacIO)\n\n# create a STAC collection for\
                \ the process\ncollection_id = subfolder\ndate = datetime.now().strftime(\"\
                %Y-%m-%d\")\n\ndates = [\n    datetime.strptime(f\"{date}T00:00:00\"\
                , \"%Y-%m-%dT%H:%M:%S\"),\n    datetime.strptime(f\"{date}T23:59:59\"\
                , \"%Y-%m-%dT%H:%M:%S\"),\n]\n\ncollection = pystac.Collection(\n\
                \    id=collection_id,\n    description=\"description\",\n    extent=pystac.Extent(\n\
                \        spatial=pystac.SpatialExtent([[-180, -90, 180, 90]]),\n \
                \       temporal=pystac.TemporalExtent(intervals=[[min(dates), max(dates)]]),\n\
                \    ),\n    title=\"Processing results\",\n    href=f\"s3://{bucket}/{subfolder}/collection.json\"\
                ,\n    stac_extensions=[],\n    keywords=[\"keyword1\", \"keyword2\"\
                ],\n    license=\"proprietary\",\n)\n\n\nfor item in cat.get_items():\n\
                \    item.set_collection(collection)\n    collection.add_item(item)\n\
                \    for key, asset in item.get_assets().items():\n        s3_path\
                \ = os.path.normpath(\n            os.path.join(os.path.join(subfolder,\
                \ item.id, asset.href))\n        )\n        print(f\"upload {asset.href}\
                \ to s3://{bucket}/{s3_path}\",file=sys.stderr)\n        client.upload_file(\n\
                \            asset.get_absolute_href(),\n            bucket,\n   \
                \         s3_path,\n        )\n        asset.href = f\"s3://{bucket}/{s3_path}\"\
                \n        item.add_asset(key, asset)\ncollection.update_extent_from_items()\n\
                \n# Access the item-assets extension\nitem_assets_ext = ItemAssetsExtension.ext(collection,\
                \ add_if_missing=True)\nif ItemAssetsExtension.get_schema_uri() not\
                \ in collection.stac_extensions:\n    collection.stac_extensions.append(ItemAssetsExtension.get_schema_uri())\n\
                \nitem_assets = {}\nfor item in collection.get_items():\n    # Loop\
                \ over the assets in the item and create AssetDefinitions for each\n\
                \    for asset_key, asset in item.assets.items():\n        # Create\
                \ AssetDefinition from existing asset properties\n        # remove\
                \ the statistics and histogram from the extra fields (raster extension)\n\
                \        asset.extra_fields[\"raster:bands\"][0].pop(\"statistics\"\
                )\n        asset.extra_fields[\"raster:bands\"][0].pop(\"histogram\"\
                )\n        asset_definition = AssetDefinition.create(\n          \
                \  title=asset.title,\n            description=asset.description,\n\
                \            media_type=asset.media_type,\n            roles=asset.roles,\n\
                \            extra_fields=asset.extra_fields,\n        )\n       \
                \ # Add the asset definition to the collection's item assets\n   \
                \     item_assets[asset_key] = asset_definition\ncat.clear_items()\n\
                \ncat.add_child(collection)\n\ncat.normalize_hrefs(f\"s3://{bucket}/{subfolder}\"\
                )\n\nfor item in collection.get_items():\n    for index, link in enumerate(item.links):\n\
                \      if link.rel in [\"root\"]:\n          item.links.pop(index)\n\
                \    # upload item to S3\n    logger.info(f\"upload {item.id} to s3://{bucket}/{subfolder}\"\
                )\n    pystac.write_file(item, item.get_self_href())\n\n# upload collection\
                \ to S3\nlogger.info(f\"upload collection.json to s3://{bucket}/{subfolder}\"\
                )\nfor index, link in enumerate(collection.links):\n    if link.rel\
                \ in [\"root\"]:\n        collection.links.pop(index)\npystac.write_file(collection,\
                \ collection.get_self_href())\n\n# upload catalog to S3\nlogger.info(f\"\
                upload catalog.json to s3://{bucket}/{subfolder}\")\nfor index, link\
                \ in enumerate(cat.links):\n  if link.rel in [\"root\"]:\n      cat.links.pop(index)\n\
                pystac.write_file(cat, cat.get_self_href())\n\nshutil.rmtree(\"/tmp/catalog/\"\
                )\n\nprint(f\"s3://{bucket}/{subfolder}/catalog.json\", file=sys.stdout)"
              entryname: stage.py
          InlineJavascriptRequirement: {}
          ResourceRequirement: {}
        stdout: message
    on_stage:
      in:
        aoi: aoi
        bands: bands
        epsg: epsg
        item_1: node_stage_in/item_1_out
        item_2: node_stage_in_1/item_2_out
      out:
      - stac_catalog
      run: '#main'
- class: Workflow
  doc: Water bodies detection based on NDWI and otsu threshold applied to a single
    Sentinel-2 COG STAC item
  id: main
  inputs:
    aoi:
      doc: area of interest as a bounding box
      label: area of interest
      type: string
    bands:
      default:
      - green
      - nir08
      doc: bands used for the NDWI
      label: bands used for the NDWI
      type: string[]
    epsg:
      default: EPSG:4326
      doc: EPSG code
      label: EPSG code
      type: string
    item_1:
      doc: Reference to a STAC item
      label: STAC item reference
      type: Directory
    item_2:
      doc: Optional reference to a STAC item
      label: Optional STAC item reference
      type: Directory?
  label: Water bodies detection based on NDWI and the otsu threshold
  outputs:
  - id: stac_catalog
    outputSource:
    - step/stac-catalog
    type: Directory
  requirements: []
  steps:
    step:
      in:
        aoi: aoi
        band: bands
        epsg: epsg
        item_1: item_1
        item_2: item_2
      out:
      - stac-catalog
      run: '#clt'
- arguments:
  - pattern-7
  baseCommand:
  - vegetation-index
  class: CommandLineTool
  hints:
    DockerRequirement:
      dockerPull: docker.io/library/vegetation-indexes:latest
  id: clt
  inputs:
    aoi:
      inputBinding:
        prefix: --aoi
      type: string
    band:
      type:
      - inputBinding:
          prefix: --band
        items: string
        type: array
    epsg:
      inputBinding:
        prefix: --epsg
      type: string
    item_1:
      inputBinding:
        prefix: --input-item-1
      type: Directory
    item_2:
      inputBinding:
        prefix: --input-item-2
      type: Directory?
  outputs:
    stac-catalog:
      outputBinding:
        glob: .
      type: Directory
  requirements:
    EnvVarRequirement:
      envDef:
        PATH: $PATH:/app/envs/vegetation-index/bin
    InlineJavascriptRequirement: {}
    ResourceRequirement:
      coresMax: 1
      ramMax: 512
$namespaces:
  s: https://schema.org/
cwlVersion: v1.0
s:softwareVersion: 1.0.0
schemas:
- http://schema.org/version/9.0/schemaorg-current-http.rdf

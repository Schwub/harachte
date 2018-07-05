from ruamel.yaml import YAML

if 'MODEL' not in locals():
    _yaml = YAML()
    _stream = open("model.yml", "r")
    MODEL = _yaml.load(_stream)

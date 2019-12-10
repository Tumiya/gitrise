# Gitrise 

A Bitrise trigger in pure `bash` 🎉!


## Usage
1. ```chmod +x gitrise.sh```  
2. ```gitrise.sh [options]```  

```
Usage: gitrise [options]

[options]
  -w, --workflow      <string>    Bitrise Workflow
  -b, --branch        <string>    Git Branch
  -e, --env           <string>    List of environment variables in the form of key1:value1,key2:value2"
  -a, --access-token  <string>    Bitrise access token
  -s, --slug          <string>    Bitrise project slug
  -v, --version                   App version
  -d, --debug                     Debug mode enabled
  -h, --help                      Print this help text
```

## API Reference

Please see [here](https://api-docs.bitrise.io/#/) for Bitrise API Reference 

## Tests

To run the unit tests, use the following command in the project directory
```bash
./tests/test_runner
```
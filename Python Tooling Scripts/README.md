## Tooling Scripts
All Python scripts for small tooling purposes using IT Glue API will
reside in this folder

## Requirements
You will need Python >3.6 installed in your system

## Getting started

#### 1. Python installation
First, you will need to make sure you have Python 3.6 with setuptools,
pip and venv installed.
You can follow the steps [here](http://docs.python-guide.org/en/latest/starting/installation/)
to install Python 3 in your system.

#### 2. Creating virtual environment
Once you have Python 3.6 installed, create the Python
virtual environment in the root of this project with the following command:

    python3 -m venv .venv


#### 3. Activate virtual environment
To activate the virtual environment, use the command below that corresponds to your OS.
##### Unix or MacOS

    source .venv/bin/activate

##### Windows

    .venv\Scripts\activate.bat


#### 4. Install dependancies
Now we need to install the script dependancies using pip.

    pip install -r requirements.txt

## Copy Flexible Asset Types Between IT Glue Accounts
### Requirements
- Both accounts must reside in the same region (in North America or Europe)
- Valid API Keys from both accounts

### 1. Create `params.json` file
Copy the `params_example.json` to a file
named `params.json` at the same folder level.

- `SourceAccountAPIKey` - This is the API Key of the IT Glue account from which
the flexible asset types are copied
- `APIUrl` - For North American accounts, use `https://api.itglue.com` and for
EU accounts, use `https://api.eu.itglue.com`
- `TargetAccountAPIKey` - This is the API Key of the IT Glue account to which
flexible asset types are copied


### 2. Run command
To initiate copying of the flexible asset types, run
```
python copy_flexible_asset_types.py
```


### 3. Notes
* If there are flexible asset types with the same name in the target account as the
types in the source account, the script will not update the existing types in
the target account.
* Console output will indicate if any of the flexible asset types encounter an
IT Glue API error during the copy. Please fix error prior to re-running the script.
* Re-running the script will not duplicate the copying of flexible asset types.
* Order of Flexible asset type copying is:
    1. Types without any flexible asset type tag fields
    1. Types with flexible asset type tag fields
    1. Types with *only* flexible asset type tag fields
* If there are cyclical dependency between types and their tags, it will not create the tag field that creates a circle dependency

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
If there are flexible asset types with the same name in the target account as the
types in the source account, the script will not update the existing types in the target account.
import itglue
import json
import os
import re

DIR_PATH = os.path.dirname(os.path.realpath(__file__))
EXCLUDE_KEYS = ['flexible_asset_type_id', 'created_at', 'updated_at', 'id']


class ITGlueError(Exception):
    pass


def set_connection_creds(api_key):
    itglue.connection.api_key = api_key


def get_api_url_and_key():
    with open('{}/params.json'.format(DIR_PATH)) as file:
        params = json.load(file)
        itglue.connection.api_url = params['APIUrl']
        return params['SourceAccountAPIKey'], params['TargetAccountAPIKEy']


def get_all_flex_types(api_key):
    """Get all flexible asset types from source account"""
    set_connection_creds(api_key)
    flex_types = itglue.FlexibleAssetType.get()
    return flex_types


def sort_types(target_api_key, flex_types):
    """Create flexible asset types that does not have a
    flexible asset type tag field in the new account
    Returns 2 lists:
    * Created types in the new account with its corresponding new ID
    * List of flexible asset fields with tag flexible asset types
    """
    fa_types_matching = {}
    tag_fields = []
    all_fields = get_all_fields(flex_types)
    for flex_type in flex_types:
        flex_id = flex_type.id
        tagged_fields, new_fields = extract_tag_type(flex_id, all_fields[flex_id])
        tag_fields.extend(tagged_fields)
        flex_type_attr = extract_attributes(flex_type.attributes)
        updated_flex_type = itglue.FlexibleAssetType(**flex_type_attr)
        print('creating type %s' % updated_flex_type.attributes['name'])
        created_type = create_new_flex_types(target_api_key, updated_flex_type, new_fields)
        fa_types_matching[flex_id] = created_type.id
    return fa_types_matching, tag_fields


def extract_field_id(field):
    tag_id = re.search('(?<=FlexibleAssetType: )\d+', field.attributes['tag_type'])
    return tag_id.group(0)


def extract_tag_type(type_id, fields):
    tagged_fields = []
    updated_fields = fields
    for index, field in enumerate(fields):
        attr = field.attributes
        if attr['kind'] == 'Tag' and ('FlexibleAssetType:' in attr['tag_type']):
            del updated_fields[index]
            tagged_fields.append({type_id: field})
    return tagged_fields, updated_fields


def update_field_tag_type(fields, new_type_ids):
    for field in fields:
        for key, value in field.items():
            tag_id = extract_field_id(value)
            value.attributes['tag_type'] = 'FlexibleAssetType: {}'.format(new_type_ids[tag_id])
            value.attributes['flexible_asset_type_id'] = new_type_ids[key]
            value.create()
    return fields


def create_new_flex_types(api_key, new_type, new_fields):
    set_connection_creds(api_key)
    try:
        created_type = new_type.create(flexible_asset_fields=new_fields)
        return created_type
    except itglue.connection.RequestError as e:
        if "has already been taken" in str(e):
            created_type = itglue.FlexibleAssetType.filter(name=new_type.attributes['name'])
            return created_type[0]
        else:
            raise e


def get_all_fields(flex_types):
    all_fields = {}
    for type in flex_types:
        fields = get_flex_asset_fields(type)
        all_fields[type.id] = fields
    return all_fields


def get_flex_asset_fields(flex_type):
    updated_fields = []
    flex_asset_fields = itglue.FlexibleAssetField.get(parent=flex_type)
    if len(flex_asset_fields) < 0:
        return ITGlueError('This flexible asset type {} does not have any fields.'.format(flex_type.name))
    for field in flex_asset_fields:
        field_attr = extract_attributes(field.attributes)
        flex_field = itglue.FlexibleAssetField(**field_attr)
        updated_fields.append(flex_field)
    return updated_fields


def extract_attributes(attributes):
    new_attribute = attributes
    for key in EXCLUDE_KEYS:
        new_attribute.pop(key, None)
    return new_attribute


def copy_flexible_asset_type(api_key, type_name, flex_fields):
    set_connection_creds(api_key)
    new_flex_asset_type = itglue.FlexibleAssetType(name=type_name)
    new_flex_asset_type.create(flexible_asset_fields=flex_fields)
    print(new_flex_asset_type)


def main():
    source_api, target_api = get_api_url_and_key()
    flex_types = get_all_flex_types(source_api)
    smo_types, tagged_list = sort_types(target_api, flex_types)
    fields = update_field_tag_type(tagged_list, smo_types)
    print(fields)


if __name__ == '__main__':
    main()

import itglue
import json
import os
import re

DIR_PATH = os.path.dirname(os.path.realpath(__file__))
EXCLUDE_KEYS = ['flexible_asset_type_id', 'created_at', 'updated_at', 'id']


class ITGlueError(Exception):
    pass


def copy_flex_types(target_api_key, flex_types):
    """Create flexible asset types that does not have a
    flexible asset type tag field in the new account
    Returns 3 lists:
    * Created types in the new account with its corresponding new ID
    * List of flexible asset fields with tag-type of another flexible asset types
    * List of flexible asset types with only tag-types of "FlexibleAssetType"
    """
    fa_types_matching = {}
    tag_fields = []
    all_fields = get_all_fields(flex_types)
    tags_only_types = []
    for flex_type in flex_types:
        type = find_or_initialize_flex_type(target_api_key, flex_type.attributes['name'])
        flex_id = flex_type.id
        if not type.id:
            tagged_fields, new_fields = extract_tag_type(flex_id, all_fields[flex_id])
            flex_type_attr = extract_attributes(flex_type.attributes)
            updated_flex_type = itglue.FlexibleAssetType(**flex_type_attr)
            if new_fields:
                created_type = create_new_flex_types(target_api_key, updated_flex_type, new_fields)
                fa_types_matching[flex_id] = created_type.id
                tag_fields.extend(tagged_fields)
            else:
                tag_type = {'id': flex_id,
                            'type': updated_flex_type,
                            'fields': all_fields[flex_id]}
                tags_only_types.append(tag_type)
        else:
            fa_types_matching[flex_id] = type.id
    return fa_types_matching, tag_fields, tags_only_types


def create_field_tag_type(fields, new_type_ids):
    """Create new FlexibleAssetField with the new flex type ID"""
    for field in fields:
        for key, value in field.items():
            new_field = update_tag_type_id(value, new_type_ids)
            if new_field and (key in new_type_ids.keys()):
                new_field.attributes['flexible_asset_type_id'] = new_type_ids[key]
                new_field.create()
            else:
                print('Unable to create tag field for flexible asset type ID: {}'.format(key))


def create_tags_only_types(target_api, types, new_type_ids):
    """Copy types that only has FlexibleAssetType tag fields"""
    while types:
        type = types.pop()
        updated_fields = []
        for field in type['fields']:
            new_field = update_tag_type_id(field, new_type_ids)
            if new_field:
                updated_fields.append(new_field)
            else:
                types.append(type)
        if updated_fields:
            created_type = create_new_flex_types(target_api, type['type'], updated_fields)
            new_type_ids[type['id']] = created_type.id


def extract_tag_type(type_id, fields):
    """Remove all fields that have a FlexibleAssetType tag-type"""
    tagged_fields = []
    fields_copy = fields[:]
    for index, field in enumerate(fields_copy[:]):
        attr = field.attributes
        if attr['kind'] == 'Tag' and ('FlexibleAssetType:' in attr['tag_type']):
            tagged_fields.append({type_id: field})
            fields_copy.remove(field)
    return tagged_fields, fields_copy


def update_tag_type_id(field, new_type_ids):
    """Update tag field with the new flexible asset type ID in target account"""
    tag_id = extract_field_id(field)
    try:
        field.attributes['tag_type'] = 'FlexibleAssetType: {}'.format(new_type_ids[tag_id])
        return field
    except KeyError:
        return False


def find_or_initialize_flex_type(api_key, type_name):
    """
    Returns type with the same name in the target account or initialize
    a new flexible asset type
    """
    set_connection_creds(api_key)
    type = itglue.FlexibleAssetType.first_or_initialize(name=type_name)
    if type.id:
        print('{} '.format(type_name).ljust(50, '.'), end='')
        print('already exists')
    return type


def create_new_flex_types(api_key, new_type, new_fields):
    set_connection_creds(api_key)
    flex_name = new_type.attributes['name']
    print('{} '.format(flex_name).ljust(50, '.'), end='')
    try:
        created_type = new_type.create(flexible_asset_fields=new_fields)
        print('copied')
        return created_type
    except Exception as e:
        print('please fix error')
        raise e


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


def extract_field_id(field):
    tag_id = re.search('(?<=FlexibleAssetType: )\d+', field.attributes['tag_type'])
    return tag_id.group(0)


def get_all_fields(flex_types):
    all_fields = {}
    for type in flex_types:
        fields = get_flex_asset_fields(type)
        all_fields[type.id] = fields
    return all_fields


def get_flex_asset_fields(flex_type):
    """Create new flexible asset fields with original attributes"""
    updated_fields = []
    flex_asset_fields = itglue.FlexibleAssetField.get(parent=flex_type)
    if not flex_asset_fields:
        return ITGlueError('This flexible asset type {} does not have any fields.'.format(flex_type.attributes['name']))
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


def main():
    source_api, target_api = get_api_url_and_key()
    flex_types = get_all_flex_types(source_api)
    type_id_maapping, tagged_list, tags_only_types = copy_flex_types(target_api, flex_types)
    create_field_tag_type(tagged_list, type_id_maapping)
    create_tags_only_types(target_api, tags_only_types, type_id_maapping)


if __name__ == '__main__':
    main()

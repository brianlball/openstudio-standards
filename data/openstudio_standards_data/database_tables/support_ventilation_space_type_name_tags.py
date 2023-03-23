from database_engine.database import DBOperation
from database_engine.database_util import getattr_either

TABLE_NAME = "support_ventilation_space_type_name_tags"

RECORD_HELP = """
Must provide a dict that contains following key value pairs:
ventilation_space_type_name: TEXT
"""

CREATE_ventilation_space_type_name = f"""
CREATE TABLE IF NOT EXISTS {TABLE_NAME}
(
ventilation_space_type_name TEXT UNIQUE NOT NULL PRIMARY KEY
);
"""

INSERT_SPACE_TAG = f"""
    INSERT INTO {TABLE_NAME}
    (ventilation_space_type_name)
    VALUES (?);
"""


RECORD_TEMPLATE = {
    "ventilation_space_type_name": "",
}


class VentSpaceTagTable(DBOperation):
    def __init__(self):
        super(VentSpaceTagTable, self).__init__(
            table_name=TABLE_NAME,
            record_template=RECORD_TEMPLATE,
            initial_data_directory=f"database_files/{TABLE_NAME}",
        )

    def get_record_info(self):
        """
        A function to return the record info of the table
        :return:
        """
        return RECORD_HELP

    def _preprocess_record(self, record):
        """

        :param record: dict
        :return:
        """

        return (getattr_either("ventilation_space_type_name", record),)

    def _get_create_table_query(self):
        return CREATE_ventilation_space_type_name

    def _get_insert_record_query(self):
        return INSERT_SPACE_TAG

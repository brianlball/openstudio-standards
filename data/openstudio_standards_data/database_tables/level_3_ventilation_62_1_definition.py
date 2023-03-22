import sqlite3

from database_engine.database import DBOperation
from database_engine.database_util import is_float, getattr_either

RECORD_HELP = """
Must provide a tuple that contains:
ventilation_primary_space_type: TEXT
ventilation_secondary_space_type: TEXT
ventilation_per_person: NUMERIC
ventilation_per_person_unit: TEXT
ventilation_per_area: NUMERIC
ventilation_per_area_unit: TEXT,
occupancy_per_area: NUMERIC,
occupancy_per_area_unit: TEXT
air_class: INTEGER
os: TEXT
annotation: TEXT (optional)
"""

CREATE_VENT_DEF_62_1_TABLE = """
CREATE TABLE IF NOT EXISTS %s
(id INTEGER PRIMARY KEY, 
ventilation_primary_space_type TEXT NOT NULL, 
ventilation_secondary_space_type TEXT NOT NULL,
ventilation_per_person NUMERIC,
ventilation_per_person_unit TEXT DEFAULT 'cfm/person',
ventilation_per_area NUMERIC,
ventilation_per_area_unit TEXT DEFAULT 'cfm/ft2',
occupancy_per_area NUMERIC,
occupancy_per_area_unit TEXT DEFAULT 'ppl/1000 ft2',
air_class INTEGER,
os TEXT,
annotation TEXT);
"""

INSERT_A_VENT_RECORD = """
    INSERT INTO %s (ventilation_primary_space_type, 
ventilation_secondary_space_type, ventilation_per_person, ventilation_per_person_unit, 
ventilation_per_area, ventilation_per_area_unit, occupancy_per_area, occupancy_per_area_unit, air_class, os, annotation) 
VALUES (?, ?, ?, ? ,? ,? , ?, ?, ?, ?, ?);
"""

RECORD_TEMPLATE = {
    "ventilation_primary_space_type": "",
    "ventilation_secondary_space_type": "",
    "ventilation_per_person": 0.0,
    "ventilation_per_person_unit": "cfm/person",
    "ventilation_per_area": 0.0,
    "ventilation_per_area_unit": "cfm/ft2",
    "occupancy_per_area": 0.0,
    "occupancy_per_area_unit": "ppl/1000 ft2",
    "air_class": 0,
    "os": "",
    "annotation": "",
}


class VentDef621(DBOperation):
    def __init__(self, table_name, initial_data_directory):
        super(VentDef621, self).__init__(
            table_name=table_name,
            record_template=RECORD_TEMPLATE,
            initial_data_directory=initial_data_directory,
        )

    def get_record_info(self):
        """
        A function to return the record info of the table
        :return:
        """
        return RECORD_HELP

    def validate_record_datatype(self, record):
        float_expected = [
            "ventilation_per_person",
            "ventilation_per_area",
            "occupancy_per_area",
        ]

        for f in float_expected:
            if record.get(f):
                assert is_float(
                    record.get(f)
                ), f"{f} requires to be numeric data type, instead got {record[f]}"

    def _preprocess_record(self, record):
        """

        :param record: dict
        :return:
        """

        return (
            getattr_either("ventilation_primary_space_type", record),
            getattr_either("ventilation_secondary_space_type", record),
            getattr_either("ventilation_per_person", record),
            getattr_either("ventilation_per_person_unit", record, "cfm/person"),
            getattr_either("ventilation_per_area", record),
            getattr_either("ventilation_per_area_unit", record, "cfm/ft2"),
            getattr_either("occupancy_per_area", record),
            getattr_either("occupancy_per_area_unit", record, "ppl/1000 ft2"),
            getattr_either("air_class", record),
            getattr_either("os", record),
            getattr_either("annotation", record, ""),
        )

    def _get_create_table_query(self):
        return CREATE_VENT_DEF_62_1_TABLE % self.data_table_name

    def _get_insert_record_query(self):
        return INSERT_A_VENT_RECORD % self.data_table_name

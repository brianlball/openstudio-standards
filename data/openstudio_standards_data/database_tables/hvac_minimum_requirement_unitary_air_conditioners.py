from database_engine.database import DBOperation
from database_engine.database_util import is_float, getattr_either

RECORD_HELP = """
Must provide a tuple that contains:
template: TEXT
cooling_type: TEXT
heating_type: TEXT
subcategory: TEXT
minimum_capacity: NUMERIC
maximum_capacity: NUMERIC
start_date: TEXT
end_date: TEXT
minimum_seasonal_efficiency: NUMERIC
minimum_energy_efficiency_ratio: NUMERIC
minimum_integrated_part_load_value: NUMERIC
minimum_integrated_energy_efficiency_ratio: NUMERIC
ptac_eer_coefficient_1: NUMERIC
ptac_eer_coefficient_2: NUMERIC
minimum_scop: NUMERIC
cool_cap_ft: TEXT
cool_cap_fflow: TEXT
cool_eir_ft: TEXT
cool_eir_fflow: TEXT
cool_plf_fplr: TEXT
annotation: TEXT (optional)
"""

CREATE_HVAC_REQUIREMENT_UNITARY_AIR_CONDITIONERS_TABLE = """
CREATE TABLE IF NOT EXISTS %s
(id INTEGER PRIMARY KEY, 
template TEXT NOT NULL, 
cooling_type TEXT NOT NULL,
heating_type TEXT NOT NULL,
subcategory TEXT NOT NULL,
minimum_capacity NUMERIC,
maximum_capacity NUMERIC,
start_date TEXT,
end_date TEXT,
minimum_seasonal_efficiency NUMERIC,
minimum_energy_efficiency_ratio NUMERIC,
minimum_integrated_part_load_value NUMERIC,
minimum_integrated_energy_efficiency_ratio NUMERIC,
ptac_eer_coefficient_1 NUMERIC,
ptac_eer_coefficient_2 NUMERIC,
minimum_scop NUMERIC,
cool_cap_ft TEXT,
cool_cap_fflow TEXT,
cool_eir_ft TEXT,
cool_eir_fflow TEXT,
cool_plf_fplr TEXT,
annotation TEXT);
"""

INSERT_A_UNITARY_AIR_CONDITIONERS_RECORD = """
    INSERT INTO %s (
template, 
cooling_type,
heating_type,
subcategory,
minimum_capacity,
maximum_capacity,
start_date,
end_date,
minimum_seasonal_efficiency,
minimum_energy_efficiency_ratio,
minimum_integrated_part_load_value,
minimum_integrated_energy_efficiency_ratio,
ptac_eer_coefficient_1,
ptac_eer_coefficient_2,
minimum_scop,
cool_cap_ft,
cool_cap_fflow,
cool_eir_ft,
cool_eir_fflow,
cool_plf_fplr,
annotation
) 
VALUES (?, ?, ?, ? ,? , ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
"""

RECORD_TEMPLATE = {
    "template": "",
    "cooling_type": "",
    "heating_type": "",
    "subcategory": "",
    "minimum_capacity": 0.0,
    "maximum_capacity": 0.0,
    "start_date": "",
    "end_date": "",
    "minimum_seasonal_efficiency": 0.0,
    "minimum_energy_efficiency_ratio": 0.0,
    "minimum_integrated_part_load_value": 0.0,
    "minimum_integrated_energy_efficiency_ratio": 0.0,
    "ptac_eer_coefficient_1": 0.0,
    "ptac_eer_coefficient_2": 0.0,
    "minimum_scop": 0.0,
    "cool_cap_ft": "",
    "cool_cap_fflow": "",
    "cool_eir_ft": "",
    "cool_eir_fflow": "",
    "cool_plf_fplr": "",
    "annotation": "",
}


class HVACMinimumRequirementUnitaryAirConditioners(DBOperation):
    def __init__(self, table_name, initial_data_directory):
        super(HVACMinimumRequirementUnitaryAirConditioners, self).__init__(
            table_name=table_name,
            record_template=RECORD_TEMPLATE,
            initial_data_directory=initial_data_directory,
            create_table_query=CREATE_HVAC_REQUIREMENT_UNITARY_AIR_CONDITIONERS_TABLE % table_name,
            insert_record_query=INSERT_A_UNITARY_AIR_CONDITIONERS_RECORD % table_name
        )

    def get_record_info(self):
        """
        A function to return the record info of the table
        :return:
        """
        return RECORD_HELP

    def validate_record_datatype(self, record):
        str_expected = [
            "template",
            "cooling_type",
            "start_date",
            "end_date",
            "cool_cap_ft",
            "cool_cap_fflow",
            "cool_eir_ft",
            "cool_eir_fflow",
            "cool_plf_fplr",
        ]

        for f in str_expected:
            if record.get(f):
                assert isinstance(
                    record[f], str
                ), f"{f} requires to be a string, instead got {record[f]}"

        float_expected = [
            "minimum_capacity",
            "maximum_capacity",
            "minimum_seasonal_efficiency",
            "minimum_energy_efficiency_ratio",
            "minimum_integrated_part_load_value",
            "minimum_integrated_energy_efficiency_ratio",
            "ptac_eer_coefficient_1",
            "ptac_eer_coefficient_2",
            "minimum_scop",
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
            getattr_either("template", record),
            getattr_either("cooling_type", record),
            getattr_either("heating_type", record),
            getattr_either("subcategory", record),
            getattr_either("minimum_capacity", record),
            getattr_either("maximum_capacity", record),
            getattr_either("start_date", record),
            getattr_either("end_date", record),
            getattr_either("minimum_seasonal_efficiency", record),
            getattr_either("minimum_energy_efficiency_ratio", record),
            getattr_either("minimum_integrated_part_load_value", record),
            getattr_either("minimum_integrated_energy_efficiency_ratio", record),
            getattr_either("ptac_eer_coefficient_1", record),
            getattr_either("ptac_eer_coefficient_2", record),
            getattr_either("minimum_scop", record),
            getattr_either("cool_cap_ft", record),
            getattr_either("cool_cap_fflow", record),
            getattr_either("cool_eir_ft", record),
            getattr_either("cool_eir_fflow", record),
            getattr_either("cool_plf_fplr", record),
            getattr_either("annotation", record),
        )

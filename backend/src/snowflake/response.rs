use serde::Deserialize;
use std::collections::HashMap;

#[derive(Deserialize)]
pub struct StatementResponse {
    #[serde(rename = "resultSetMetaData")]
    metadata: ResultSetMetaData,
    data: Vec<Vec<Option<String>>>,
}

#[derive(Deserialize)]
struct ResultSetMetaData {
    #[serde(rename = "rowType")]
    row_type: Vec<ColumnMeta>,
}

#[derive(Deserialize)]
struct ColumnMeta {
    name: String,
}

impl StatementResponse {
    pub fn rows(&self) -> Vec<Row> {
        self.data.iter().map(|cells| self.row(cells)).collect()
    }

    fn row(&self, cells: &[Option<String>]) -> Row {
        let values = self
            .metadata
            .row_type
            .iter()
            .zip(cells)
            .map(|(col, cell)| (col.name.clone(), cell.clone()))
            .collect();
        Row { values }
    }
}

pub struct Row {
    values: HashMap<String, Option<String>>,
}

impl Row {
    pub fn get(&self, column: &str) -> Option<&str> {
        self.values.get(column).and_then(|v| v.as_deref())
    }
}

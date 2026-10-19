local enum TableRowKindEnum
  'header'
  'delimiter'
  'body'
end

local record TableRowKindEnumProps
  type TableRowKindEnum = TableRowKindEnum

  HEADER: TableRowKindEnum
  DELIMITER: TableRowKindEnum
  BODY: TableRowKindEnum
end

local TABLE_ROW_KIND_ENUM <const>: TableRowKindEnumProps = {
  HEADER = 'header',
  DELIMITER = 'delimiter',
  BODY = 'body',
}

return TABLE_ROW_KIND_ENUM

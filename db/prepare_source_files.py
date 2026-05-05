from pathlib import Path


ROOT = Path(r"c:\Users\vaibh\OneDrive\Desktop\AdventureWorks-oltp")
OUT = ROOT / "adventureworks-bi" / "tmp"

FILES = [
    "SalesOrderHeader.csv",
    "SalesOrderDetail.csv",
    "SalesPerson.csv",
    "SalesPersonQuotaHistory.csv",
    "SalesTerritory.csv",
    "Customer.csv",
    "Person.csv",
    "EmailAddress.csv",
    "BusinessEntityAddress.csv",
    "Address.csv",
    "StateProvince.csv",
    "Product.csv",
    "ProductSubcategory.csv",
    "ProductCategory.csv",
    "Employee.csv",
    "EmployeeDepartmentHistory.csv",
    "Department.csv",
    "EmployeePayHistory.csv",
]


def normalize_custom_delimited(text: str) -> str:
    rows = []
    for row in text.split("&|"):
        row = row.strip("\r\n")
        if not row:
            continue
        cols = row.split("+|")
        if cols and cols[-1] == "":
            cols = cols[:-1]
        rows.append("\t".join(cols))
    return "\n".join(rows) + ("\n" if rows else "")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for filename in FILES:
        src = ROOT / filename
        dst = OUT / filename.replace(".csv", ".tsv")
        text = src.read_text(encoding="utf-8", errors="replace")

        if "+|" in text and "&|" in text:
            normalized = normalize_custom_delimited(text)
        else:
            normalized = text.replace("\r\n", "\n")

        dst.write_text(normalized, encoding="utf-8", newline="\n")
        print(f"prepared {dst}")


if __name__ == "__main__":
    main()

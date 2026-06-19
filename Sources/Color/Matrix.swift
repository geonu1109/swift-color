// Fixed-size linear algebra for the color conversions. The dimensions are part
// of each type (integer generic parameters), so a mis-sized multiply is a
// compile error rather than a runtime surprise, and the constant 3×3 color
// matrices read as three rows instead of a flat nine-element array.

/// A vector of `Double`s whose length is part of its type. The `[count of …]`
/// storage is an `InlineArray`, so it is held inline with no heap allocation.
struct Vector<let count: Int> {
    var components: [count of Double]

    init(_ components: [count of Double]) {
        self.components = components
    }

    subscript(_ index: Int) -> Double {
        components[index]
    }
}

/// A row-major matrix whose dimensions are part of its type. A `Matrix<R, C>`
/// is a linear map from a `Vector<C>` to a `Vector<R>`; the `*` operator
/// enforces that pairing at compile time. The `[rows of [columns of …]]`
/// storage is `InlineArray`, so the constant color matrices are held inline.
struct Matrix<let rows: Int, let columns: Int> {
    var rowVectors: [rows of [columns of Double]]

    init(_ rowVectors: [rows of [columns of Double]]) {
        self.rowVectors = rowVectors
    }

    /// Matrix–vector product. The operand's length must equal the column count
    /// (`Vector<columns>`); the result's length is the row count — both checked
    /// by the compiler.
    static func * (matrix: Matrix, vector: Vector<columns>) -> Vector<rows> {
        var result = [rows of Double](repeating: 0)
        for row in 0..<rows {
            var sum = 0.0
            for column in 0..<columns {
                sum += matrix.rowVectors[row][column] * vector[column]
            }
            result[row] = sum
        }
        return Vector(result)
    }
}

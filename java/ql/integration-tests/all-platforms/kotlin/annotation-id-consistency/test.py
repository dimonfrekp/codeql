def test(codeql, java):
    codeql.database.create(
        command=["kotlinc test.kt -d out", "javac User.java -cp out", "kotlinc ktUser.kt -cp out"]
    )

import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "ts.mila.expense.dev"
            resValue(type = "string", name = "app_name", value = "G-SPEND")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "ts.mila.expense"
            resValue(type = "string", name = "app_name", value = "G-SPEND")
        }
    }
}
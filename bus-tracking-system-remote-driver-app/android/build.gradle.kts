// قسم buildscript هو المسؤول عن تحميل الأدوات التي يستخدمها Gradle نفسه
buildscript {
    // متغير لتحديد إصدار لغة Kotlin
    val kotlin_version = "1.9.23"

    // هنا نحدد المستودعات التي سيبحث فيها Gradle عن أدوات البناء
    repositories {
        google()
        mavenCentral()
    }

    // هنا نحدد الأدوات نفسها التي يحتاجها
    dependencies {
        // أداة بناء لغة Kotlin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        // أداة بناء Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.2.2")
    }
}

// هذا القسم الذي كان لديك بالفعل، وهو يحدد مستودعات المكتبات للمشروع بأكمله
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// الكود المخصص الذي كان لديك بالفعل - سنحتفظ به كما هو
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
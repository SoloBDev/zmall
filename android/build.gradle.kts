// allprojects {
//     repositories {
//         google()
//         mavenCentral()
//         // jcenter()
//          // Include the libs directory that contains telebirr inapp sdk
//         flatDir {
//           dirs '../libs'
//         }
//     }
// }

// rootProject.buildDir = '../build'
// subprojects {
//     project.buildDir = "${rootProject.buildDir}/${project.name}"
// }
// subprojects {
//     project.evaluationDependsOn(':app')
// }

// tasks.register("clean", Delete) {
//     delete rootProject.buildDir
// }

//for kotlin based
allprojects {
    repositories {
        google()
        mavenCentral()
        // jcenter() is deprecated
        // Include the libs directory that contains telebirr inapp sdk
        flatDir {
            dirs("../libs")
        }
    }
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}


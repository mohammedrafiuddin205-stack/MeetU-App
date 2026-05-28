#!/bin/bash

WORKSPACE="MeetU-App"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# 1. Setup Android SDK
echo "Setting up Android SDK..."
export ANDROID_HOME="$PWD/android-sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline.zip
unzip -q cmdline.zip -d "$ANDROID_HOME/cmdline-tools"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
rm cmdline.zip

export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
yes | sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 2. Directory Structure
echo "Creating project structure..."
APP_DIR="app/src/main"
JAVA_DIR="$APP_DIR/java/com/example/callingapp"
RES_DIR="$APP_DIR/res"

mkdir -p "$JAVA_DIR"
mkdir -p "$RES_DIR/layout"
mkdir -p "$RES_DIR/values"
mkdir -p "$RES_DIR/drawable"
mkdir -p "$RES_DIR/mipmap-anydpi-v26"
mkdir -p "app"

# 3. Generate Keystore
echo "Generating Keystore..."
keytool -genkeypair -v -keystore app/release.jks -keyalg RSA -keysize 2048 -validity 10000 \
    -alias meetu_alias \
    -dname "CN=MeetU, OU=Premium, O=MeetU, L=San Francisco, ST=CA, C=US" \
    -storepass meetu123 -keypass meetu123

# 4. Gradle Configuration
echo "Writing Gradle files..."

cat << 'EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "MeetU"
include ':app'
EOF

cat << 'EOF' > build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.0'
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
EOF

cat << 'EOF' > app/build.gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}

android {
    namespace 'com.example.callingapp'
    compileSdk 34

    defaultConfig {
        applicationId "com.example.callingapp"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    signingConfigs {
        release {
            storeFile file("release.jks")
            storePassword "meetu123"
            keyAlias "meetu_alias"
            keyPassword "meetu123"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    
    // Agora
    implementation 'io.agora.rtc:full-sdk:4.3.0'
}
EOF

cat << 'EOF' > gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
EOF

cat << EOF > local.properties
sdk.dir=$ANDROID_HOME
EOF

# 5. Firebase google-services.json Stub
echo "Writing google-services stub..."
cat << 'EOF' > app/google-services.json
{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "meetu-calling-app",
    "storage_bucket": "meetu-calling-app.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abcdef1234567890abcdef",
        "android_client_info": {
          "package_name": "com.example.callingapp"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyDummyKeyForStubDoNotUseInProd123"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
EOF

# 6. AndroidManifest.xml
echo "Writing AndroidManifest..."
cat << 'EOF' > $APP_DIR/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.autofocus" />

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="MeetU"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.MeetU">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:theme="@style/Theme.MeetU.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <service
            android:name=".BackgroundService"
            android:exported="false"
            android:foregroundServiceType="dataSync" />
    </application>
</manifest>
EOF

# 7. Resources: Colors, Drawables, Layouts
echo "Writing Resources..."

cat << 'EOF' > $RES_DIR/values/colors.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="bg_main">#000000</color>
    <color name="surface_dark">#121214</color>
    <color name="surface_input">#1C1C1E</color>
    <color name="accent_primary">#5B3FFF</color>
    <color name="accent_secondary">#A052FF</color>
    <color name="status_online">#00E676</color>
    <color name="status_offline">#8E8E93</color>
    <color name="status_error">#FF3B30</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#8A8A8E</color>
</resources>
EOF

cat << 'EOF' > $RES_DIR/values/themes.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.MeetU" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/accent_primary</item>
        <item name="colorPrimaryVariant">@color/accent_secondary</item>
        <item name="colorOnPrimary">@color/text_primary</item>
        <item name="android:statusBarColor">@color/bg_main</item>
        <item name="android:windowBackground">@color/bg_main</item>
    </style>
    <style name="Theme.MeetU.NoActionBar">
        <item name="windowActionBar">false</item>
        <item name="windowNoTitle">true</item>
    </style>
</resources>
EOF

cat << 'EOF' > $RES_DIR/drawable/action_button_bg.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/accent_primary" />
    <corners android:radius="16dp" />
</shape>
EOF

cat << 'EOF' > $RES_DIR/drawable/card_surface_bg.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/surface_dark" />
    <corners android:radius="20dp" />
</shape>
EOF

cat << 'EOF' > $RES_DIR/drawable/input_box_bg.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/surface_input" />
    <corners android:radius="12dp" />
    <stroke android:width="1dp" android:color="#33FFFFFF"/>
</shape>
EOF

cat << 'EOF' > $RES_DIR/drawable/square_pin_box.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="@color/surface_input" />
    <corners android:radius="12dp" />
    <stroke android:width="2dp" android:color="@color/accent_secondary"/>
</shape>
EOF

cat << 'EOF' > $RES_DIR/drawable/circular_avatar_bg.xml
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="@color/surface_input" />
    <stroke android:width="2dp" android:color="@color/accent_primary" />
</shape>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_nav_home.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_nav_contacts.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M12,12c2.21,0 4,-1.79 4,-4s-1.79,-4 -4,-4 -4,1.79 -4,4 1.79,4 4,4zM12,14c-2.67,0 -8,1.34 -8,4v2h16v-2c0,-2.66 -5.33,-4 -8,-4z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_nav_call.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M17,10.5V7c0,-0.55 -0.45,-1 -1,-1H4C3.45,6 3,6.45 3,7v10c0,0.55 0.45,1 1,1h12c0.55,0 1,-0.45 1,-1v-3.5l4,4v-11l-4,4z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_nav_rooms.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M4,4h16v16H4V4zm2,2v12h12V6H6z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/drawable/ic_nav_profile.xml
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFF" android:pathData="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2zM12,5c1.66,0 3,1.34 3,3s-1.34,3 -3,3 -3,-1.34 -3,-3 1.34,-3 3,-3zM12,19.2c-2.5,0 -4.71,-1.28 -6,-3.22 0.03,-1.99 4,-3.08 6,-3.08 1.99,0 5.97,1.09 6,3.08 -1.29,1.94 -3.5,3.22 -6,3.22z"/>
</vector>
EOF

cat << 'EOF' > $RES_DIR/mipmap-anydpi-v26/ic_launcher.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/bg_main" />
    <foreground android:drawable="@drawable/ic_nav_call" />
</adaptive-icon>
EOF

cat << 'EOF' > $RES_DIR/mipmap-anydpi-v26/ic_launcher_round.xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/bg_main" />
    <foreground android:drawable="@drawable/ic_nav_call" />
</adaptive-icon>
EOF

# Layout: Activity Main (7 Semantic States)
cat << 'EOF' > $RES_DIR/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@color/bg_main">

    <!-- FRAME WRAPPER FOR STATES -->
    <FrameLayout
        android:id="@+id/main_content_frame"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_above="@id/bottom_nav">
        
        <!-- 1. VIEW_HOME -->
        <LinearLayout android:id="@+id/view_home" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:visibility="visible">
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="MeetU" android:textSize="28sp" android:textColor="@color/text_primary" android:textStyle="bold" />
            <EditText android:layout_width="match_parent" android:layout_height="50dp" android:layout_marginTop="16dp" android:background="@drawable/input_box_bg" android:hint="Search or Start Call..." android:textColorHint="@color/text_secondary" android:textColor="@color/text_primary" android:paddingHorizontal="16dp" />
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:layout_marginTop="20dp">
                <LinearLayout android:id="@+id/btn_new_meeting" android:layout_width="0dp" android:layout_weight="1" android:layout_height="100dp" android:background="@drawable/action_button_bg" android:gravity="center" android:orientation="vertical" android:layout_marginEnd="8dp">
                    <ImageView android:layout_width="32dp" android:layout_height="32dp" android:src="@drawable/ic_nav_call" />
                    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="New Meeting" android:textColor="@color/text_primary" android:layout_marginTop="8dp"/>
                </LinearLayout>
                <LinearLayout android:id="@+id/btn_join_room" android:layout_width="0dp" android:layout_weight="1" android:layout_height="100dp" android:background="@drawable/card_surface_bg" android:gravity="center" android:orientation="vertical" android:layout_marginStart="8dp">
                    <ImageView android:layout_width="32dp" android:layout_height="32dp" android:src="@drawable/ic_nav_rooms" />
                    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Join Room" android:textColor="@color/text_primary" android:layout_marginTop="8dp"/>
                </LinearLayout>
            </LinearLayout>
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Upcoming Meeting" android:textColor="@color/text_primary" android:textStyle="bold" android:layout_marginTop="24dp" />
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:background="@drawable/card_surface_bg" android:padding="16dp" android:layout_marginTop="12dp" android:orientation="horizontal">
                <LinearLayout android:layout_width="0dp" android:layout_weight="1" android:layout_height="wrap_content" android:orientation="vertical">
                    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Team Standup" android:textColor="@color/text_primary" android:textStyle="bold" />
                    <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Today, 10:00 AM" android:textColor="@color/text_secondary" />
                </LinearLayout>
                <Button android:id="@+id/btn_join_upcoming" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Join" android:backgroundTint="@color/accent_primary" />
            </LinearLayout>
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Recent Calls" android:textColor="@color/text_primary" android:textStyle="bold" android:layout_marginTop="24dp" />
            <androidx.recyclerview.widget.RecyclerView android:id="@+id/rv_recent_calls" android:layout_width="match_parent" android:layout_height="match_parent" android:layout_marginTop="12dp" />
        </LinearLayout>

        <!-- 2. VIEW_CONTACTS -->
        <LinearLayout android:id="@+id/view_contacts" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:visibility="gone">
            <RelativeLayout android:layout_width="match_parent" android:layout_height="wrap_content">
                <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Contacts" android:textSize="28sp" android:textColor="@color/text_primary" android:textStyle="bold" />
                <ImageView android:id="@+id/btn_add_contact" android:layout_width="32dp" android:layout_height="32dp" android:layout_alignParentEnd="true" android:src="@drawable/ic_nav_profile" android:tint="@color/accent_primary" />
            </RelativeLayout>
            <EditText android:layout_width="match_parent" android:layout_height="50dp" android:layout_marginTop="16dp" android:background="@drawable/input_box_bg" android:hint="Search contacts..." android:textColorHint="@color/text_secondary" android:textColor="@color/text_primary" android:paddingHorizontal="16dp" />
            <androidx.recyclerview.widget.RecyclerView android:id="@+id/rv_contacts" android:layout_width="match_parent" android:layout_height="match_parent" android:layout_marginTop="16dp" />
        </LinearLayout>

        <!-- 3. VIEW_ADD_CONTACT_ID -->
        <LinearLayout android:id="@+id/view_add_contact_id" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:gravity="center_horizontal" android:visibility="gone">
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Add Contact" android:textSize="24sp" android:textColor="@color/text_primary" android:textStyle="bold" />
            <ImageView android:layout_width="120dp" android:layout_height="120dp" android:layout_marginTop="40dp" android:background="@drawable/circular_avatar_bg" android:padding="30dp" android:src="@drawable/ic_nav_profile" android:tint="@color/text_secondary" />
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Add using ID" android:textColor="@color/text_primary" android:textSize="18sp" android:layout_marginTop="24dp" android:textStyle="bold" />
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Enter a 6-digit ID to add or connect" android:textColor="@color/text_secondary" android:layout_marginTop="8dp" />
            <LinearLayout android:layout_width="wrap_content" android:layout_height="wrap_content" android:orientation="horizontal" android:layout_marginTop="24dp" android:gravity="center">
                <EditText android:id="@+id/pin_1" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
                <EditText android:id="@+id/pin_2" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
                <EditText android:id="@+id/pin_3" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
                <EditText android:id="@+id/pin_4" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
                <EditText android:id="@+id/pin_5" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
                <EditText android:id="@+id/pin_6" android:layout_width="45dp" android:layout_height="55dp" android:background="@drawable/square_pin_box" android:textColor="@color/text_primary" android:textSize="24sp" android:gravity="center" android:maxLength="1" android:inputType="number" android:layout_margin="4dp"/>
            </LinearLayout>
            <Button android:id="@+id/btn_continue_pin" android:layout_width="match_parent" android:layout_height="60dp" android:layout_marginTop="40dp" android:text="Continue" android:backgroundTint="@color/accent_primary" android:textSize="18sp"/>
        </LinearLayout>

        <!-- 4. VIEW_ADD_OPTIONS -->
        <LinearLayout android:id="@+id/view_add_options" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:gravity="center_horizontal" android:visibility="gone">
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="User Found!" android:textSize="24sp" android:textColor="@color/status_online" android:textStyle="bold" android:gravity="center" />
            <ImageView android:layout_width="120dp" android:layout_height="120dp" android:layout_marginTop="40dp" android:background="@drawable/circular_avatar_bg" android:padding="20dp" android:src="@drawable/ic_nav_profile" android:tint="@color/text_primary" />
            <TextView android:id="@+id/tv_found_name" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Olivia Wilson" android:textColor="@color/text_primary" android:textSize="24sp" android:layout_marginTop="16dp" android:textStyle="bold" />
            <TextView android:id="@+id/tv_found_id" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="ID: 123456" android:textColor="@color/text_secondary" android:textSize="16sp" android:layout_marginTop="4dp" />
            <Button android:id="@+id/btn_save_contact" android:layout_width="match_parent" android:layout_height="60dp" android:layout_marginTop="40dp" android:text="Save Contact" android:backgroundTint="@color/accent_primary" android:textSize="18sp"/>
            <Button android:id="@+id/btn_start_call_found" android:layout_width="match_parent" android:layout_height="60dp" android:layout_marginTop="16dp" android:text="Start Call" android:backgroundTint="@color/surface_dark" android:textSize="18sp" app:strokeColor="@color/accent_primary" app:strokeWidth="1dp" />
        </LinearLayout>

        <!-- 5. VIEW_PROFILE -->
        <LinearLayout android:id="@+id/view_profile" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:visibility="gone">
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Profile" android:textSize="28sp" android:textColor="@color/text_primary" android:textStyle="bold" />
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="vertical" android:gravity="center" android:layout_marginTop="32dp">
                <ImageView android:layout_width="100dp" android:layout_height="100dp" android:background="@drawable/circular_avatar_bg" android:src="@drawable/ic_nav_profile" android:padding="20dp" android:tint="@color/text_primary" />
                <TextView android:id="@+id/tv_profile_name" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="John Doe" android:textColor="@color/text_primary" android:textSize="24sp" android:textStyle="bold" android:layout_marginTop="16dp" />
                <TextView android:id="@+id/tv_profile_email" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="john@meetu.com" android:textColor="@color/text_secondary" />
                <TextView android:id="@+id/tv_profile_my_id" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="My ID: ------" android:textColor="@color/accent_secondary" android:textStyle="bold" android:layout_marginTop="8dp" />
            </LinearLayout>
            <Button android:id="@+id/btn_logout" android:layout_width="match_parent" android:layout_height="50dp" android:layout_marginTop="40dp" android:text="Logout" android:backgroundTint="@color/status_error" />
        </LinearLayout>

        <!-- 6. VIEW_IN_CALL (1-on-1) -->
        <RelativeLayout android:id="@+id/view_in_call" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_main" android:visibility="gone">
            <!-- Remote Video Fullscreen -->
            <FrameLayout android:id="@+id/remote_video_view_container" android:layout_width="match_parent" android:layout_height="match_parent" />
            <!-- Header -->
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="24dp" android:gravity="center_vertical" android:background="#66000000">
                <TextView android:id="@+id/tv_incall_name" android:layout_width="0dp" android:layout_weight="1" android:layout_height="wrap_content" android:text="Alice Johnson" android:textColor="@color/text_primary" android:textSize="20sp" android:textStyle="bold" />
                <TextView android:id="@+id/tv_incall_timer" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="00:00" android:textColor="@color/text_primary" />
            </LinearLayout>
            <!-- Local Video Floating -->
            <FrameLayout android:id="@+id/local_video_view_container" android:layout_width="120dp" android:layout_height="160dp" android:layout_above="@id/call_actions_bar" android:layout_alignParentEnd="true" android:layout_marginEnd="16dp" android:layout_marginBottom="16dp" android:background="@drawable/card_surface_bg" android:elevation="4dp" android:clipToOutline="true" />
            <!-- Bottom Actions -->
            <LinearLayout android:id="@+id/call_actions_bar" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_alignParentBottom="true" android:orientation="horizontal" android:padding="24dp" android:gravity="center" android:background="#99121214">
                <ImageView android:id="@+id/btn_mute" android:layout_width="56dp" android:layout_height="56dp" android:background="@drawable/circular_avatar_bg" android:src="@drawable/ic_nav_profile" android:padding="16dp" android:layout_marginHorizontal="8dp" />
                <ImageView android:id="@+id/btn_video" android:layout_width="56dp" android:layout_height="56dp" android:background="@drawable/circular_avatar_bg" android:src="@drawable/ic_nav_call" android:padding="16dp" android:layout_marginHorizontal="8dp" />
                <ImageView android:id="@+id/btn_end_call" android:layout_width="72dp" android:layout_height="72dp" android:background="@drawable/circular_avatar_bg" android:backgroundTint="@color/status_error" android:src="@drawable/ic_nav_call" android:padding="20dp" android:layout_marginHorizontal="8dp" />
            </LinearLayout>
        </RelativeLayout>

        <!-- 7. VIEW_ROOM_GROUP_CALL -->
        <RelativeLayout android:id="@+id/view_room_group_call" android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/bg_main" android:visibility="gone">
            <LinearLayout android:id="@+id/room_header" android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="24dp" android:gravity="center_vertical" android:background="#66000000">
                <TextView android:id="@+id/tv_room_name" android:layout_width="0dp" android:layout_weight="1" android:layout_height="wrap_content" android:text="Team Meeting" android:textColor="@color/text_primary" android:textSize="20sp" android:textStyle="bold" />
                <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="Active" android:textColor="@color/status_online" />
            </LinearLayout>
            <!-- 3x2 Grid for 6 participants -->
            <GridLayout android:id="@+id/grid_room_videos" android:layout_width="match_parent" android:layout_height="match_parent" android:layout_below="@id/room_header" android:layout_above="@id/room_actions_bar" android:rowCount="3" android:columnCount="2" android:padding="8dp">
                <!-- Dynamite containers created in Java -->
            </GridLayout>
            <!-- Bottom Actions -->
            <LinearLayout android:id="@+id/room_actions_bar" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_alignParentBottom="true" android:orientation="horizontal" android:padding="24dp" android:gravity="center" android:background="#99121214">
                <ImageView android:id="@+id/btn_room_end_call" android:layout_width="72dp" android:layout_height="72dp" android:background="@drawable/circular_avatar_bg" android:backgroundTint="@color/status_error" android:src="@drawable/ic_nav_call" android:padding="20dp" />
            </LinearLayout>
        </RelativeLayout>
        
        <!-- LOGIN VIEW (Utility for Auth) -->
        <LinearLayout android:id="@+id/view_login" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="32dp" android:gravity="center" android:visibility="gone" android:background="@color/bg_main">
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="MeetU" android:textSize="48sp" android:textColor="@color/accent_primary" android:textStyle="bold" android:layout_marginBottom="40dp" />
            <EditText android:id="@+id/et_email" android:layout_width="match_parent" android:layout_height="60dp" android:background="@drawable/input_box_bg" android:hint="Email" android:textColorHint="@color/text_secondary" android:textColor="@color/text_primary" android:paddingHorizontal="16dp" android:layout_marginBottom="16dp" />
            <EditText android:id="@+id/et_password" android:layout_width="match_parent" android:layout_height="60dp" android:background="@drawable/input_box_bg" android:hint="Password" android:inputType="textPassword" android:textColorHint="@color/text_secondary" android:textColor="@color/text_primary" android:paddingHorizontal="16dp" android:layout_marginBottom="24dp" />
            <Button android:id="@+id/btn_login" android:layout_width="match_parent" android:layout_height="60dp" android:text="Login / Sign Up" android:backgroundTint="@color/accent_primary" android:textSize="18sp" />
        </LinearLayout>

    </FrameLayout>

    <!-- BOTTOM NAVIGATION -->
    <LinearLayout android:id="@+id/bottom_nav" android:layout_width="match_parent" android:layout_height="70dp" android:layout_alignParentBottom="true" android:background="@color/surface_dark" android:orientation="horizontal" android:gravity="center" android:elevation="8dp">
        <ImageView android:id="@+id/nav_home" android:layout_width="0dp" android:layout_weight="1" android:layout_height="match_parent" android:src="@drawable/ic_nav_home" android:padding="20dp" android:tint="@color/accent_primary" />
        <ImageView android:id="@+id/nav_contacts" android:layout_width="0dp" android:layout_weight="1" android:layout_height="match_parent" android:src="@drawable/ic_nav_contacts" android:padding="20dp" android:tint="@color/text_secondary" />
        <FrameLayout android:id="@+id/nav_call_center" android:layout_width="0dp" android:layout_weight="1" android:layout_height="match_parent">
            <ImageView android:layout_width="50dp" android:layout_height="50dp" android:layout_gravity="center" android:background="@drawable/action_button_bg" android:src="@drawable/ic_nav_call" android:padding="12dp" />
        </FrameLayout>
        <ImageView android:id="@+id/nav_rooms" android:layout_width="0dp" android:layout_weight="1" android:layout_height="match_parent" android:src="@drawable/ic_nav_rooms" android:padding="20dp" android:tint="@color/text_secondary" />
        <ImageView android:id="@+id/nav_profile" android:layout_width="0dp" android:layout_weight="1" android:layout_height="match_parent" android:src="@drawable/ic_nav_profile" android:padding="20dp" android:tint="@color/text_secondary" />
    </LinearLayout>

</RelativeLayout>
EOF

cat << 'EOF' > $RES_DIR/layout/item_contact.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="12dp"
    android:gravity="center_vertical"
    android:background="@color/bg_main"
    android:layout_marginBottom="8dp">
    <FrameLayout android:layout_width="50dp" android:layout_height="50dp">
        <ImageView android:layout_width="match_parent" android:layout_height="match_parent" android:background="@drawable/circular_avatar_bg" android:src="@drawable/ic_nav_profile" android:padding="10dp" android:tint="@color/text_primary" />
        <View android:id="@+id/status_dot" android:layout_width="12dp" android:layout_height="12dp" android:layout_gravity="bottom|end" android:background="@drawable/circular_avatar_bg" android:backgroundTint="@color/status_offline" />
    </FrameLayout>
    <TextView android:id="@+id/tv_name" android:layout_width="0dp" android:layout_weight="1" android:layout_height="wrap_content" android:text="Contact Name" android:textColor="@color/text_primary" android:textSize="16sp" android:textStyle="bold" android:layout_marginStart="16dp" />
    <ImageView android:id="@+id/btn_call_contact" android:layout_width="40dp" android:layout_height="40dp" android:src="@drawable/ic_nav_call" android:background="@drawable/circular_avatar_bg" android:backgroundTint="@color/accent_secondary" android:padding="8dp" />
</LinearLayout>
EOF

# 8. Java Sources
echo "Writing Java files..."

cat << 'EOF' > $JAVA_DIR/BackgroundService.java
package com.example.callingapp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;

public class BackgroundService extends Service {
    private static final String CHANNEL_ID = "MeetU_Channel";
    private static final String CALL_CHANNEL_ID = "MeetU_Call_Channel";
    private ListenerRegistration callListener;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannels();
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("MeetU Active")
                .setContentText("Listening for incoming calls...")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
                
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
        } else {
            startForeground(1, notification);
        }
        listenForCalls();
    }

    private void createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(new NotificationChannel(CHANNEL_ID, "Background Service", NotificationManager.IMPORTANCE_LOW));
            manager.createNotificationChannel(new NotificationChannel(CALL_CHANNEL_ID, "Incoming Calls", NotificationManager.IMPORTANCE_HIGH));
        }
    }

    private void listenForCalls() {
        String uid = FirebaseAuth.getInstance().getUid();
        if (uid == null) return;
        callListener = FirebaseFirestore.getInstance().collection("calls")
            .whereEqualTo("receiverId", uid)
            .whereEqualTo("status", "ringing")
            .addSnapshotListener((snapshots, e) -> {
                if (e != null || snapshots == null || snapshots.isEmpty()) return;
                
                String callId = snapshots.getDocuments().get(0).getId();
                String callerId = snapshots.getDocuments().get(0).getString("callerId");

                Intent fullScreenIntent = new Intent(this, MainActivity.class);
                fullScreenIntent.putExtra("INCOMING_CALL", true);
                fullScreenIntent.putExtra("CALL_ID", callId);
                fullScreenIntent.putExtra("CALLER_ID", callerId);
                fullScreenIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                PendingIntent fullScreenPendingIntent = PendingIntent.getActivity(this, 0, fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

                NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CALL_CHANNEL_ID)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setContentTitle("Incoming Call")
                        .setContentText("Someone is calling you")
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setCategory(NotificationCompat.CATEGORY_CALL)
                        .setFullScreenIntent(fullScreenPendingIntent, true)
                        .setAutoCancel(true);

                NotificationManager manager = getSystemService(NotificationManager.class);
                manager.notify(2, builder.build());
            });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        if (callListener != null) callListener.remove();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
EOF

cat << 'EOF' > $JAVA_DIR/MainActivity.java
package com.example.callingapp;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;
import android.widget.*;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import io.agora.rtc2.Constants;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.video.VideoCanvas;

public class MainActivity extends AppCompatActivity {

    private FirebaseAuth mAuth;
    private FirebaseFirestore db;
    private RtcEngine rtcEngine;
    private static final String AGORA_APP_ID = "0810267927b4400490af954557a44417";
    
    private View vHome, vContacts, vAddContactId, vAddOptions, vProfile, vInCall, vRoomCall, vLogin, bottomNav;
    private ImageView navHome, navContacts, navRooms, navProfile;
    private FrameLayout navCallCenter;
    
    private FrameLayout localVideoContainer, remoteVideoContainer;
    private GridLayout gridRoomVideos;
    private String currentChannel = null;
    private String myCallingId = null;
    private String foundUserId = null;
    
    private boolean isMuted = false;
    private boolean isVideoOff = false;

    private static final int PERMISSION_REQ_ID = 22;
    private static final String[] REQUESTED_PERMISSIONS = {
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA,
            Manifest.permission.POST_NOTIFICATIONS
    };

    private final IRtcEngineEventHandler mRtcEventHandler = new IRtcEngineEventHandler() {
        @Override
        public void onUserJoined(int uid, int elapsed) {
            runOnUiThread(() -> setupRemoteVideo(uid));
        }
        @Override
        public void onUserOffline(int uid, int reason) {
            runOnUiThread(() -> {
                remoteVideoContainer.removeAllViews();
                if (vRoomCall.getVisibility() == View.VISIBLE) {
                    // Logic to remove from grid can go here
                } else {
                    endCall();
                }
            });
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mAuth = FirebaseAuth.getInstance();
        db = FirebaseFirestore.getInstance();

        initViews();
        setupNavListeners();
        checkPermissions();

        if (mAuth.getCurrentUser() == null) {
            showView(vLogin);
        } else {
            initApp();
        }

        findViewById(R.id.btn_login).setOnClickListener(v -> {
            String email = ((EditText)findViewById(R.id.et_email)).getText().toString();
            String pwd = ((EditText)findViewById(R.id.et_password)).getText().toString();
            if(email.isEmpty() || pwd.isEmpty()) return;
            
            mAuth.signInWithEmailAndPassword(email, pwd).addOnCompleteListener(task -> {
                if(task.isSuccessful()) {
                    initApp();
                } else {
                    mAuth.createUserWithEmailAndPassword(email, pwd).addOnCompleteListener(task2 -> {
                        if(task2.isSuccessful()) {
                            generateUserIdAndInit();
                        } else {
                            Toast.makeText(this, "Auth Failed", Toast.LENGTH_SHORT).show();
                        }
                    });
                }
            });
        });
    }

    private void generateUserIdAndInit() {
        FirebaseUser user = mAuth.getCurrentUser();
        if(user == null) return;
        myCallingId = String.format("%06d", new Random().nextInt(999999));
        
        Map<String, Object> userData = new HashMap<>();
        userData.put("email", user.getEmail());
        userData.put("callingId", myCallingId);
        userData.put("status", "Online");
        
        db.collection("users").document(user.getUid()).set(userData);
        
        Map<String, Object> idData = new HashMap<>();
        idData.put("uid", user.getUid());
        idData.put("callingId", myCallingId);
        db.collection("callingIds").document(myCallingId).set(idData);
        
        initApp();
    }

    private void initApp() {
        showView(vHome);
        bottomNav.setVisibility(View.VISIBLE);
        startService(new Intent(this, BackgroundService.class));
        
        db.collection("users").document(mAuth.getUid()).get().addOnSuccessListener(doc -> {
            if(doc.exists()) {
                myCallingId = doc.getString("callingId");
                ((TextView)findViewById(R.id.tv_profile_email)).setText(doc.getString("email"));
                ((TextView)findViewById(R.id.tv_profile_my_id)).setText("My ID: " + myCallingId);
                db.collection("users").document(mAuth.getUid()).update("status", "Online");
            }
        });

        initAgora();
        loadContacts();
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if(intent != null && intent.getBooleanExtra("INCOMING_CALL", false)) {
            String callId = intent.getStringExtra("CALL_ID");
            joinCall(callId);
        }
    }

    private void initViews() {
        vHome = findViewById(R.id.view_home);
        vContacts = findViewById(R.id.view_contacts);
        vAddContactId = findViewById(R.id.view_add_contact_id);
        vAddOptions = findViewById(R.id.view_add_options);
        vProfile = findViewById(R.id.view_profile);
        vInCall = findViewById(R.id.view_in_call);
        vRoomCall = findViewById(R.id.view_room_group_call);
        vLogin = findViewById(R.id.view_login);
        bottomNav = findViewById(R.id.bottom_nav);

        navHome = findViewById(R.id.nav_home);
        navContacts = findViewById(R.id.nav_contacts);
        navRooms = findViewById(R.id.nav_rooms);
        navProfile = findViewById(R.id.nav_profile);
        navCallCenter = findViewById(R.id.nav_call_center);

        localVideoContainer = findViewById(R.id.local_video_view_container);
        remoteVideoContainer = findViewById(R.id.remote_video_view_container);
        gridRoomVideos = findViewById(R.id.grid_room_videos);

        findViewById(R.id.btn_logout).setOnClickListener(v -> {
            if(mAuth.getUid() != null) db.collection("users").document(mAuth.getUid()).update("status", "Offline");
            mAuth.signOut();
            showView(vLogin);
            bottomNav.setVisibility(View.GONE);
        });
        
        findViewById(R.id.btn_add_contact).setOnClickListener(v -> showView(vAddContactId));
        
        findViewById(R.id.btn_continue_pin).setOnClickListener(v -> {
            String pin = getPinFromBoxes();
            if(pin.length() == 6) lookupId(pin);
        });

        findViewById(R.id.btn_save_contact).setOnClickListener(v -> {
            if(foundUserId != null) {
                Map<String, Object> c = new HashMap<>();
                c.put("uid", foundUserId);
                db.collection("users").document(mAuth.getUid()).collection("contacts").document(foundUserId).set(c);
                Toast.makeText(this, "Saved!", Toast.LENGTH_SHORT).show();
                showView(vContacts);
                loadContacts();
            }
        });

        findViewById(R.id.btn_start_call_found).setOnClickListener(v -> startCall(foundUserId));
        findViewById(R.id.btn_new_meeting).setOnClickListener(v -> startCall(null)); // Mock quick start
        
        findViewById(R.id.btn_end_call).setOnClickListener(v -> endCall());
        findViewById(R.id.btn_room_end_call).setOnClickListener(v -> endCall());
        
        findViewById(R.id.btn_mute).setOnClickListener(v -> {
            isMuted = !isMuted;
            rtcEngine.muteLocalAudioStream(isMuted);
            findViewById(R.id.btn_mute).setBackgroundTintList(ContextCompat.getColorStateList(this, isMuted ? R.color.status_error : R.color.surface_input));
        });
    }

    private String getPinFromBoxes() {
        return ((EditText)findViewById(R.id.pin_1)).getText().toString() +
               ((EditText)findViewById(R.id.pin_2)).getText().toString() +
               ((EditText)findViewById(R.id.pin_3)).getText().toString() +
               ((EditText)findViewById(R.id.pin_4)).getText().toString() +
               ((EditText)findViewById(R.id.pin_5)).getText().toString() +
               ((EditText)findViewById(R.id.pin_6)).getText().toString();
    }

    private void lookupId(String pin) {
        db.collection("callingIds").document(pin).get().addOnSuccessListener(doc -> {
            if(doc.exists()) {
                foundUserId = doc.getString("uid");
                ((TextView)findViewById(R.id.tv_found_id)).setText("ID: " + pin);
                showView(vAddOptions);
            } else {
                Toast.makeText(this, "Not Found", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupNavListeners() {
        navHome.setOnClickListener(v -> showView(vHome));
        navContacts.setOnClickListener(v -> showView(vContacts));
        navRooms.setOnClickListener(v -> showView(vRoomCall)); // For demo, directly opens grid view
        navProfile.setOnClickListener(v -> showView(vProfile));
        navCallCenter.setOnClickListener(v -> showView(vAddContactId));
    }

    private void showView(View view) {
        vHome.setVisibility(View.GONE);
        vContacts.setVisibility(View.GONE);
        vAddContactId.setVisibility(View.GONE);
        vAddOptions.setVisibility(View.GONE);
        vProfile.setVisibility(View.GONE);
        vInCall.setVisibility(View.GONE);
        vRoomCall.setVisibility(View.GONE);
        vLogin.setVisibility(View.GONE);
        view.setVisibility(View.VISIBLE);
        
        if(view == vInCall || view == vRoomCall || view == vLogin) {
            bottomNav.setVisibility(View.GONE);
        } else {
            bottomNav.setVisibility(View.VISIBLE);
        }
        
        navHome.setColorFilter(ContextCompat.getColor(this, view == vHome ? R.color.accent_primary : R.color.text_secondary));
        navContacts.setColorFilter(ContextCompat.getColor(this, view == vContacts ? R.color.accent_primary : R.color.text_secondary));
        navRooms.setColorFilter(ContextCompat.getColor(this, view == vRoomCall ? R.color.accent_primary : R.color.text_secondary));
        navProfile.setColorFilter(ContextCompat.getColor(this, view == vProfile ? R.color.accent_primary : R.color.text_secondary));
    }

    private void initAgora() {
        try {
            rtcEngine = RtcEngine.create(getBaseContext(), AGORA_APP_ID, mRtcEventHandler);
            rtcEngine.enableVideo();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void startCall(String receiverId) {
        if(receiverId == null) return;
        currentChannel = mAuth.getUid() + "_" + System.currentTimeMillis();
        
        Map<String, Object> callData = new HashMap<>();
        callData.put("callerId", mAuth.getUid());
        callData.put("receiverId", receiverId);
        callData.put("status", "ringing");
        callData.put("channel", currentChannel);
        
        db.collection("calls").document(currentChannel).set(callData);
        joinCallChannel(currentChannel);
    }

    private void joinCall(String callId) {
        db.collection("calls").document(callId).update("status", "accepted");
        joinCallChannel(callId);
    }

    private void joinCallChannel(String channel) {
        currentChannel = channel;
        showView(vInCall);
        setupLocalVideo();
        rtcEngine.joinChannel("", channel, "", 0);
    }

    private void setupLocalVideo() {
        localVideoContainer.removeAllViews();
        SurfaceView view = new SurfaceView(getBaseContext());
        view.setZOrderMediaOverlay(true);
        localVideoContainer.addView(view);
        rtcEngine.setupLocalVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, 0));
        rtcEngine.startPreview();
    }

    private void setupRemoteVideo(int uid) {
        remoteVideoContainer.removeAllViews();
        SurfaceView view = new SurfaceView(getBaseContext());
        remoteVideoContainer.addView(view);
        rtcEngine.setupRemoteVideo(new VideoCanvas(view, VideoCanvas.RENDER_MODE_HIDDEN, uid));
    }

    private void endCall() {
        if (rtcEngine != null) {
            rtcEngine.leaveChannel();
            rtcEngine.stopPreview();
        }
        if(currentChannel != null) {
            db.collection("calls").document(currentChannel).update("status", "ended");
        }
        currentChannel = null;
        showView(vHome);
    }

    private void loadContacts() {
        RecyclerView rv = findViewById(R.id.rv_contacts);
        rv.setLayoutManager(new LinearLayoutManager(this));
        if(mAuth.getUid() == null) return;
        
        db.collection("users").document(mAuth.getUid()).collection("contacts").get().addOnSuccessListener(snaps -> {
            List<String> cIds = new ArrayList<>();
            for(DocumentSnapshot d : snaps) cIds.add(d.getId());
            rv.setAdapter(new ContactAdapter(cIds));
        });
    }

    class ContactAdapter extends RecyclerView.Adapter<ContactAdapter.VH> {
        List<String> ids;
        ContactAdapter(List<String> ids) { this.ids = ids; }
        @Override public VH onCreateViewHolder(android.view.ViewGroup parent, int viewType) {
            return new VH(getLayoutInflater().inflate(R.layout.item_contact, parent, false));
        }
        @Override public void onBindViewHolder(VH holder, int position) {
            String uid = ids.get(position);
            holder.tvName.setText("User: " + uid.substring(0,5));
            holder.btnCall.setOnClickListener(v -> startCall(uid));
            db.collection("users").document(uid).addSnapshotListener((doc, e) -> {
                if(doc != null && doc.exists()) {
                    String status = doc.getString("status");
                    holder.statusDot.setBackgroundTintList(ContextCompat.getColorStateList(MainActivity.this, 
                        "Online".equals(status) ? R.color.status_online : R.color.status_offline));
                }
            });
        }
        @Override public int getItemCount() { return ids.size(); }
        class VH extends RecyclerView.ViewHolder {
            TextView tvName; View statusDot; ImageView btnCall;
            VH(View v) { super(v); tvName=v.findViewById(R.id.tv_name); statusDot=v.findViewById(R.id.status_dot); btnCall=v.findViewById(R.id.btn_call_contact); }
        }
    }

    private void checkPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)) {
            ActivityCompat.requestPermissions(this, REQUESTED_PERMISSIONS, PERMISSION_REQ_ID);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if(mAuth.getUid() != null) db.collection("users").document(mAuth.getUid()).update("status", "Offline");
        if(rtcEngine != null) RtcEngine.destroy();
    }
}
EOF

# 9. Build Execution
echo "Installing Gradle Wrapper and Building..."
wget -q https://services.gradle.org/distributions/gradle-8.2-bin.zip
unzip -q -o -d /opt/gradle gradle-8.2-bin.zip
/opt/gradle/gradle-8.2/bin/gradle wrapper --gradle-version 8.2
chmod +x gradlew

echo "Building App Release APK..."
./gradlew clean assembleRelease

echo "Build complete! APK should be located in app/build/outputs/apk/release/"

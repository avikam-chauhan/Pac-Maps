const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
var admin = require("firebase-admin");

//notification request
var http2 = require('http2');

var serviceAccount = require("/Users/mathewjoseph/Downloads/quarantraining-377bb-firebase-adminsdk-3j5v9-083f1201ea.json");

//token encription
var jose = require('jsonwebtoken'); //require('node-jose'); //require('jose');//
var fs = require('fs');
var apns2 = require("apns2")
const { APNS } = require('apns2')
const { BasicNotification } = require('apns2')
const { Token } = require('apns2')


const {
  JWE,   // JSON Web Encryption (JWE)
  JWK,   // JSON Web Key (JWK)
  JWKS,  // JSON Web Key Set (JWKS)
  JWS,   // JSON Web Signature (JWS)
  JWT,   // JSON Web Token (JWT)
  errors // errors utilized by jose
} = jose
var CryptoJS = require("crypto-js");


admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://quarantraining-377bb.firebaseio.com"
});


// admin.initializeApp(functions.config().database)

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// exports.addMessage = functions.https.onRequest(async (req, res) => {
//   // Grab the text parameter.
//   const original = req.query.text;
//   // Push the new message into Cloud Firestore using the Firebase Admin SDK.
//   const writeResult = await admin.firestore().collection('messages').add({original: original});
//   // Send back a message that we've succesfully written the message
//   res.json({result: `Message with ID: ${writeResult.id} added.`});
// });

// exports.makeUppercase = functions.database.ref('/messages/{pushId}/original')
//     .onCreate((snapshot, context) => {
//       // Grab the current value of what was written to the Realtime Database.
//       const original = snapshot.val();
//       console.log('Uppercasing', context.params.pushId, original);
//       const uppercase = original.toUpperCase();
//       // You must return a Promise when performing asynchronous tasks inside a Functions such as
//       // writing to the Firebase Realtime Database.
//       // Setting an "uppercase" sibling in the Realtime Database returns a Promise.
//       return snapshot.ref.parent.child('uppercase').set(uppercase);
//     });

// exports.helloWorld = functions.https.onRequest((req, res) => {
//   res.send("Hello from Firebase!");
//   exports.newUserCreated = functions.database.ref('/users').onCreate(event => {
//     res.send("user created")
//   })
// });

// exports.insertIntoDB = functions.https.onRequest((req, res) => {
//   const text = "SAMPLE"; //req.query.text
//   admin.database().ref('/users').push({text: text}).then(snapshot => {
//       res.redirect(303, snapshot.ref);
//   })
// });

//globalVariables
var justEdited = false;

exports.allContactedUsers = functions.database.ref('/users/{UUID}/allContactedUsers').onWrite((snapshot, context) => {
  if(!justEdited){
    justEdited = true
    const weekMS = 4*7*24*60*60*1000;

  var currentUserUUID = context.params["UUID"];
  console.log(currentUserUUID);


  // console.log("original snapshot", Object.keys(snapshot.after.val()).length); //snapshot.after.val()[0]['timeStampMS'])

  var currentTimeMS = new Date().getTime();
  console.log("currentTimeMS",currentTimeMS);

  var recentContactedUsers = [];

  for(var i = 0; i < Object.keys(snapshot.after.val()).length; i++){
    if(currentTimeMS - snapshot.after.val()[i]['timeStampMS'] <= weekMS){
      recentContactedUsers.push(snapshot.after.val()[i]);
    }
  }

  console.log(recentContactedUsers);



  admin.database().ref('/users/' + currentUserUUID + '/allContactedUsers').set(recentContactedUsers);
  

  // admin.database().ref('/users/' + currentUserUUID + '/allContactedUsers').orderByChild("timeStampMS").startAt(currentTimeMS - weekMS).endAt(currentTimeMS).once("value", function(userSnapshot) {
  //   console.log(userSnapshot.val());
  // })
  } else if(justEdited){
    justEdited = false;
  }

})

exports.contactTracing = functions.database.ref('/users/{UUID}/positiveResult').onWrite((snapshot, context) => {
  if(snapshot.after.val()) {
      
  }
})

exports.positiveResult = functions.database.ref('/users/{UUID}/positiveResult')
  .onWrite((snapshot, context) => {
    // Grab the current value of what was written to the Realtime Database.
    const radius = 10; //MILES
    console.log('UUID:', context.params["UUID"]);
    const userUUID = context.params["UUID"];



    const userLocation = admin.database().ref('/users/' + userUUID + '/location').once("value", function (locationSnapshot) {
      //POSITIVE USER LOCATION
      var positiveUserLatitude = 0;
      var positiveUserLongitude = 0;
      positiveUserLatitude = locationSnapshot.val()["latitude"];
      positiveUserLongitude = locationSnapshot.val()["longitude"];
      console.log("latitude: " + positiveUserLatitude + " longitude: " + positiveUserLongitude);

      const reference = snapshot.after.ref.parent.parent;
      let earthRadius = 3958.8;
      let lowerBound_latitude = positiveUserLatitude - (radius / earthRadius);
      let upperBound_latitude = (radius / earthRadius) + positiveUserLatitude;
      let latitudeQuery = admin.database().ref('users').orderByChild("location/latitude").startAt(lowerBound_latitude).endAt(upperBound_latitude).once("value", function (snapshot) {
        console.log("NUMBER OF CHILDREN",snapshot.numChildren());
        snapshot.forEach(function (childSnapshot) {

          // generateKey();

          var childLongitude = childSnapshot.child("location/longitude").val();
          let distance = earthRadius * Math.abs(childLongitude - positiveUserLongitude);
          // console.log("DISTANCE",distance);
          if (childSnapshot.key !== userUUID && distance <= radius) {
            var userRegistrationToken = childSnapshot.child('registrationToken').val();
            
            if(userRegistrationToken !== null){
              sendNotification(userRegistrationToken, distance);
            }

            // console.log("childLatitude:", childSnapshot.child("location/latitude").val());
            // console.log("childLongitude:", childLongitude);
            // console.log("childKey", childSnapshot.key);
            // sendNotification(childSnapshot.child("key").val())
          }
        });

      });

    });
    console.log('positiveResult VALUE:', snapshot.after.val()); //after.child('score').val()
   
  });




function sendNotification(registrationToken, distance) {
//   var host = 'https://api.sandbox.push.apple.com';
//   var path = `/3/device/${key}`

//   const client = http2.connect(host);

//   client.on('error', (err) => console.error(err));
  
//   console.log(path);

//   body = {
//     "aps": {
//         "alert": "hello",
//         "content-available": 1
//     }
// }

// headers = {
//   ':method': 'POST',
//   'apns-topic': 'com.ipaycheck.PacMan-Coronatrainer', //your application bundle ID
//   ':scheme': 'https',
//   ':path': path,
//   'authorization': `bearer ${storedKey}`
// }

// const request = client.request(headers);

// request.on('response', (headers, flags) => {
//   for (const name in headers) {
//       console.log(`${name}: ${headers[name]}`);
//   }
// });

// request.setEncoding('utf8');
// let data = ''
// request.on('data', (chunk) => { data += chunk; });
// request.write(JSON.stringify(body))
// request.on('end', () => {
//   console.log(`\n${data}`);
//   client.close();
// });
// request.end();


  // var authorizationValue = 'bearer ${storedKey}'
  
  // var options = {
  //   host: 'api.sandbox.push.apple.com',
  //   port: 443,
  //   path: '/3/device/' + String(key),
  //   method: 'POST',
  //   authorization: authorizationValue
  // };

  //   var req = https.request(options, function (res) {
  //   res.setEncoding('utf8');

  //   var body = '';

  //   res.on('data', function (chunk) {
  //     body = body + chunk;
  //   });

  //   res.on('end',function(){
  //     console.log("Body :" + body);
  //     if (res.statusCode != 200) {
  //       callback("Api call failed with response code " + res.statusCode);
  //     } else {
  //       callback(null);
  //     }
  //   });

  // });

  //  let payLoad = {
  //     "aps": {
  //       "alert": {
  //         "loc-key": "CONTACT_ALERT"
  //       }
  //     }
  //   };
  // req.write(payLoad);

  var roundedDistance =  Math.floor(distance*100)/100;

  // console.log("roundedDistance", roundedDistance);

  var bodyString = '';

  if(roundedDistance == 0){
    bodyString = `There is a user with a positive case near you`
  } else {
    bodyString = `There is a user with a positive case ${distance} miles away`
  }

  const payload = {notification: {
    title: 'REMINDER: Keep your social distance',
    body: bodyString
    }
  };
  admin.messaging().sendToDevice(registrationToken, payload);
}

// function generateKey(){
//   jose.JWK.createKey("oct", 256, { alg: "A256GCM" }).
//          then(function(result) {
//            console.log(result);
//          });
// }


//CURRENTLY USING jsonwebtoken
function generateKey(){
  
  let client = new APNS({
    team: `TFLP87PW54`,
    keyId: `123ABC456`,
    signingKey: "-----BEGIN PRIVATE KEY-----MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgzfbJ/nx1FCAEKoEG54sLOUAeAZatZdgTgyhlhqTU7dmgCgYIKoZIzj0DAQehRANCAASiylCEkedU18en9DLUBban2cGvWL+tzRyvJZrP2aPMcffzwKLB0C+LbIYDVTrF3cDREEP0Voj7sEJ9RmNez2OU-----END PRIVATE KEY-----"
  ,
    defaultTopic: `com.tablelist.Tablelist`
  })
  
  
  const deviceToken = "aESZgxdhc"
  
  let bn = new BasicNotification(deviceToken, 'Hello, World')  
  
  try {
     client.send(bn)
  } catch (err) {
    console.error(err.reason)
  }

  // admin.database().ref("keyInformation").set({
  //   "key": token,
  //   "timeStamp": currentTime
  // })

  
  
}

function base64url(source) {
  // Encode in classical base64
  encodedSource = CryptoJS.enc.Base64.stringify(source);

  // Remove padding equal characters
  encodedSource = encodedSource.replace(/=+$/, '');

  // Replace characters according to base64url specifications
  encodedSource = encodedSource.replace(/\+/g, '-');
  encodedSource = encodedSource.replace(/\//g, '_');

  return encodedSource;
}
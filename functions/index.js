const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
var admin = require("firebase-admin");

var serviceAccount = require("/Users/mathewjoseph/Downloads/quarantraining-377bb-firebase-adminsdk-3j5v9-083f1201ea.json");

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

exports.helloWorld = functions.https.onRequest((req, res) => {
  res.send("Hello from Firebase!");
  exports.newUserCreated = functions.database.ref('/users').onCreate(event => {
    res.send("user created")
  })
});

// exports.insertIntoDB = functions.https.onRequest((req, res) => {
//   const text = "SAMPLE"; //req.query.text
//   admin.database().ref('/users').push({text: text}).then(snapshot => {
//       res.redirect(303, snapshot.ref);
//   })
// });

exports.makeUppercase = functions.database.ref('/users/{UUID}/positiveResult')
    .onWrite((snapshot, context) => {
      // Grab the current value of what was written to the Realtime Database.
      const radius = 10; //MILES
      console.log('UUID:', context.params["UUID"]);
      const userUUID = context.params["UUID"];
      
      const userLocation = admin.database().ref('/users/' + userUUID + '/location').once("value", function(locationSnapshot) {
            var userLatitude = 0;
            var userLongitude = 0;
            userLatitude = locationSnapshot.val()["latitude"];
            userLongitude = locationSnapshot.val()["longitude"];
            console.log("latitude: " + userLatitude + " longitude: " + userLongitude);
            admin.database().ref('/users').once("value", function(snapshot1){
              // console.log("ENTERED", snapshot1.val());
              snapshot1.forEach(function(childSnapshot){
                var location =  childSnapshot.child("location").val();
                if(location["latitude"] < userLatitude + radius && location["longitude"] < userLatitude + radius && childSnapshot.key != userUUID){
                  console.log("NEARBY POSITIVE RESULT");
                }
              });
            });
            // console.log(snapshot);

          });      
      console.log('positiveResult VALUE:', snapshot.after.val()); //after.child('score').val()
      // const uppercase = original.toUpperCase();
      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to the Firebase Realtime Database.
      // Setting an "uppercase" sibling in the Realtime Database returns a Promise.
      // return snapshot.ref.parent.child('score').set(uppercase);

      // const arrayOfUsers = admin.database().ref('/users/{UUID}/location');
      // console.log(arrayOfUsers);
    });

    // const userLocation = admin.database().ref('/users/84B88DE2-2DD1-4B86-B0D3-A9435D08F534/location').once("value", function(snapshot) {
    //   userLatitude = snapshot.val()["latitude"];
    //   userLongitude = snapshot.val()["longitude"];
    //   console.log("latitude:" + userLatitude + "longitude:" + userLongitude);
    // });
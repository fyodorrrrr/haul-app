import 'package:flutter/material.dart';


class seller_registration_page extends StatelessWidget{
  const seller_registration_page ({super.key});

  @override build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.width;

    return Scaffold(
        body: Stack(
        children: <Widget> [  
            Positioned(
              top: screenHeight * .16,
              left: screenWidth * .05,
              right: screenWidth * .05,

                child: Image.asset(
                  "assets/images/vendor.png",
                  // width: screenWidth,
                  // height: screenHeight
                  )
            ),
            Center(
              child: Container(
              margin: EdgeInsets.fromLTRB(0, screenHeight * .6, 0, 0),
              width: 300,
              height: 500,
              decoration: BoxDecoration(
                color:Colors.white,
                  borderRadius:BorderRadius.all(Radius.circular(20)), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 5,
                      spreadRadius: 2,
                      offset: Offset(0, 4)
                    )
                  ]
              ),
              // margin: EdgeInsets.fromLTRB(20, 300, 20, 0),
              child: Stack(
                children: <Widget> [
                  Text(
                    "Start Selling"
                  ),

                  Positioned(
                    left: 10,
                    top: 100,
                    bottom: 10,
                    right: 10,
                    child: Container(
                      child: TextField(
                      decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 176, 174, 174),
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      ),
                    hintText: "Business Name"
                    ),
                  ),
                )
                )
                ]
              )
            ),)
        ]
        )
        );
  }
    
}
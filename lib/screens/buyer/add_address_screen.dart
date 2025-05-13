import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";


class add_address_page extends StatefulWidget{
  const add_address_page({super.key});

  _addAddressState createState() => _addAddressState();
}


class _addAddressState extends State<add_address_page>{
  // bool _isSwitched = false;
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;


    return Scaffold(
      appBar: AppBar(
        title: Text("New Address",
        style: GoogleFonts.poppins(
          fontSize: 21
        )),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 5.0,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: const Color.fromARGB(255, 202, 202, 202),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Contact",
                    style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w300
                    ))
                  )
                ]
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5),
                child: TextField(
                  style: GoogleFonts.poppins(
                    fontSize: 15
                  ),
                  decoration: InputDecoration(
                    hintText: "Full Name"
                  )
                )
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5),
                child: TextField(
                  style: GoogleFonts.poppins(
                    fontSize: 15
                  ),
                  decoration: InputDecoration(
                    hintText: "Phone Number"
                  )
                )
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Address",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w300
                    ))
                  )
                ]
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5),
                child: TextField(
                  style: GoogleFonts.poppins(
                    fontSize: 15
                  ),
                  decoration: InputDecoration(
                    hintText: "Region, Province, City/Town, Barangay"
                  )
                )
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5),
                child: TextField(
                  style: GoogleFonts.poppins(
                    fontSize: 15
                  ),
                  decoration: InputDecoration(
                    hintText: "Postal Code"
                  )
                )
              ),
               Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w300
                    ))
                  )
                ]
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      child: Text("Labeled as",
                        style: GoogleFonts.poppins(
                          fontSize: 15
                        ))
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero
                                )
                              ),
                              onPressed: (){},
                              child: Text("Work")
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero
                                )
                                ),
                                onPressed: (){},
                                child: Text("Home")
                              )
                            )
                          ]
                        )
                      )
                    )
                  ]
                )
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 0.5),
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      child: Row(
                        children: [
                          Text("Set As Default Address",
                            style: GoogleFonts.poppins(
                            fontSize: 15
                          )),
                      //   Expanded(
                      //   child: Align(
                      //     alignment: Alignment.centerRight,
                      //     child: Switch(
                      //       value: _isSwitched,
                      //       onChanged: (newValue) {
                      //         setState((){
                      //           _isSwitched = newValue;
                      //         });
                      //       }
                      //     )
                      //   )
                      // )
                        
                        ]
                      ),
                    )
                  ]
                )
              )
            ]
          )
        )
      )
    );
  }
}
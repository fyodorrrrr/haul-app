import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "/screens/buyer/add_address_screen.dart";

class saved_address_page extends StatefulWidget {
  const saved_address_page({super.key});

  @override
  _savedAddressState createState() => _savedAddressState();
}

class _savedAddressState extends State<saved_address_page>{
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

      return Scaffold(
        appBar: AppBar(
          title: Text("Saved Addresses",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,)),
          
          backgroundColor: Colors.white,
          elevation: 5.0,
          shadowColor: Colors.black.withOpacity(0.4),
          centerTitle: true
        ),
        body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: const Color.fromARGB(255, 202, 202, 202),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Row(
                children : [
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: Text("Address",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w300
                    ))
                  )
                ]
              ),
              //This is for default address
              Container(
                margin: EdgeInsets.only(top: 4),
                width: MediaQuery.of(context).size.width,
                color: const Color.fromARGB(255, 238, 237, 237),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10,),
                      child: Row(
                        children: [
                        Text("Name of Seller",
                          style: GoogleFonts.poppins(
                          fontSize: 18,
                          ),
                        ),
                        Text(" |",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w100
                        )),
                        Text("number of seller")
                        ]
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 5),
                      child: Row(
                        children: [
                          Text("House No., ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Building, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Street Name, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                        ]
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 15),
                      child: Row(
                        children: [
                          Text("Barangay, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("City, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Province, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Region, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Postal Code, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          ))
                        ]
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.only(bottom: 15, left: 10),
                      child: Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.4)
                              )
                            ),
                            child: Text("DEFAULT",
                            style: GoogleFonts.poppins(
                            fontSize: 11
                            )),
                            onPressed: (){}
                          ) 
                        ]
                      )
                    ),
                  ]
                ),
              ),
              // this is for pickup address
              Container(
                margin: EdgeInsets.only(top: 0.5),
                width: MediaQuery.of(context).size.width,
                color: const Color.fromARGB(255, 238, 237, 237),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10,),
                      child: Row(
                        children: [
                        Text("Name of Seller",
                          style: GoogleFonts.poppins(
                          fontSize: 18,
                          ),
                        ),
                        Text(" |",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w100
                        )),
                        Text("number of seller")
                        ]
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 5),
                      child: Row(
                        children: [
                          Text("House No., ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Building, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Street Name, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                        ]
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 15),
                      child: Row(
                        children: [
                          Text("Barangay, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("City, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Province, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Region, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          )),
                          Text("Postal Code, ",
                          style: GoogleFonts.poppins(
                            fontSize: 11
                          ))
                        ]
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.only(bottom: 15, left: 10),
                      child: Row(
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.4)
                              )
                            ),
                            child: Text("PICK UP ADDRESS",
                            style: GoogleFonts.poppins(
                            fontSize: 11
                            )),
                            onPressed: (){}
                          ) 
                        ]
                      )
                    ),
                  ]
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 0.5),
                width: MediaQuery.of(context).size.width,
                color: const Color.fromARGB(255, 238, 237, 237),
                child: Column(
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.add_rounded),
                      label: Text("Add Address"),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const add_address_page())
                        );
                      }
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

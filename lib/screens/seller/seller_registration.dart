import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class seller_registration_page extends StatefulWidget{
  const seller_registration_page ({super.key});
  @override

_SellerRegState createState() => _SellerRegState();
}
  class _SellerRegState extends State<seller_registration_page>{
    List<String> countries = ['Philippines', 'Japan', 'America'];
    List<String> regions = ['Calabarzon', 'Mimaropa'];
    String? selectedRegion;
    String? selectedCountry;
    @override build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.width;

    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(

            child: Stack(
              children: <Widget> [  
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: Align(
                  alignment: Alignment.topLeft,
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(Icons.arrow_back,
                      color: Colors.black)
                    )
                  )
               ),
                Align(
                  alignment: Alignment.topCenter,
                    child: Image.asset(
                    "assets/images/vendor.png",
                    height: 18_0,
                    width: 200 
                  )
                ),

                Center(
                  child: Container(
                  margin: EdgeInsets.fromLTRB(0, screenHeight * .45, 0, 0),
                  width: 300,
                  height: 550,
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
                  child: Stack(
                  children: <Widget> [
                    Positioned(
                      top: 10,
                      left: 45,
                        child: Text(
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600
                          ),
                          "Start Selling"
                        ), 
                      ),
                    Positioned(
                      top: 50,
                      left: 60,
                      child: Text(
                        "Be part of the seller community",
                        style: GoogleFonts.poppins(
                          fontSize: 9.5
                        )
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                          child: Column(
                          children: [
                            Text(
                              "Business Information",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 18
                              )
                            )
                          ] 
                        )
                      )
                    ),
                    Padding(
                          padding: EdgeInsets.fromLTRB(20, 140, 20, 0),
                      child: Column(
                        children: [
                          TextField(
                            style: GoogleFonts.poppins(
                              fontSize: 11
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 220, 219, 219),
                              hintText: "Business Name",
                              hintStyle: TextStyle(
                                color: Colors.black
                              )
                            )
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 25),
                              child: TextField(
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                ),

                                decoration: InputDecoration(

                                  filled: true,
                                  fillColor: const Color.fromARGB(255, 220, 219, 219),
                                  hintText: "Address Line 1",
                                  hintStyle: TextStyle(
                                    color: Colors.black
                                  )
                                )
                              )
                          ),
                          TextField(
                            style: GoogleFonts.poppins(
                              fontSize: 11
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(255, 220, 219, 219),
                              hintText: "Address Line 2",
                              hintStyle: TextStyle(
                                color: Colors.black
                              )
                            )
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 25, right: 10),
                                  child: SizedBox(
                                    width: 125,
                                    child: TextField(
                                      style: GoogleFonts.poppins(
                                      fontSize: 11
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 220, 219, 219),
                                      hintText: "City",
                                      hintStyle: TextStyle(
                                      color: Colors.black
                                      )
                                    )
                                  ),
                                )
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 25),
                                  child: SizedBox(
                                    width: 125,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: selectedRegion,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color.fromARGB(255, 220, 219, 219),
                                        hintText: "Region",
                                      ),
                                      icon: Icon(Icons.arrow_drop_down),
                                      onChanged: (String? newRegion){
                                        setState(() {
                                          selectedRegion = newRegion;
                                        });
                                      },
                                      items: regions.map((String value){
                                        return DropdownMenuItem <String>(
                                          value: value,
                                          child: Text(value)
                                        );
                                      }).toList()
                                    )
                                  )
                                )
                              ]
                            ),
                          Row(
                              children: [
                                Padding(
                                padding: EdgeInsets.only(top: 15, right: 10),
                                child: SizedBox(
                                  width: 125,
                                  child: TextField(
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.black
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 220, 219, 219),
                                      hintText: "Zip Code",
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 11
                                      )
                                    )
                                  )
                                  )
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 15),
                                child: SizedBox(
                                  width: 125,
                                  child: DropdownButtonFormField<String?>(
                                    value: selectedCountry,
                                    isExpanded: true,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color:Colors.black
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color.fromARGB(255, 220, 219, 219),
                                      hintText: "Country",
                                    ),
                                  icon: Icon(Icons.arrow_drop_down),

                                  onChanged: (String? newValue){
                                    setState((){
                                      selectedCountry = newValue;
                                    });
                                  },
                                  items: countries.map((String value){
                                    return DropdownMenuItem <String>(
                                      value: value,
                                      child: Text(value)
                                    );
                                  }).toList()
                                )

                                )
                              )
                            ]
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                width: 100,
                                height: 45,
                                child: FloatingActionButton(
                                  onPressed: (){},
                                  child: Text(
                                    "NEXT",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold
                                    ))
                                )
                              ) 
                            )
                          ) 
                        ]
                      )
                    ),
                  ]
                ),
              ),
            )
          ]
        )
      )
      )
    );
    }
  }
  
    
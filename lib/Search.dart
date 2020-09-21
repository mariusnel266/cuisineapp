import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop/Helper/Section_Model.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';

import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/String.dart';
import 'Product_Detail.dart';

class Search extends StatefulWidget {
  @override
  _StateSearch createState() => _StateSearch();
}

class _StateSearch extends State<Search> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // bool _isLoading = false;
  List<Product> productList = [];
  List<Product> searchresult = [];

  @override
  void initState() {
    super.initState();
    searchresult.clear();
    getProduct();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
          title: TextField(
            controller: _controller,
            style: TextStyle(
              color: Colors.white,
            ),
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              prefixIcon: Icon(Icons.search, color: primary),
              hintText: 'Search',
              hintStyle: TextStyle(color: primary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onChanged: searchOperation,
          ),
        ),
        body: (searchresult.isNotEmpty || _controller.text.isNotEmpty)
            ? ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: searchresult.length,
                itemBuilder: (context, i) {
                  return listItem(i);
                })
            : Container());
    /* : _isLoading
            ? getProgress()
            :getNoItem())*/
  }

  Widget listItem(int index) {
    print("desc*****${productList[index].desc}");
    return Card(
      child: InkWell(
        child: Row(
          children: <Widget>[
            CachedNetworkImage(
              imageUrl: productList[index].image,
              height: 90.0,
              width: 90.0,
              fit: BoxFit.fill,
              placeholder: (context, url) => placeHolder(90),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      productList[index].name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Html(
                      data: '<p>${productList[index].desc}</p>',

                      /*style: {
                        "p": Style(
                            margin: EdgeInsets.all(0),
                            color: Colors.grey,
                            fontSize: FontSize.small),
                      },*/
                      //maxLines: 2,
                      //  overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            InkWell(
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.remove,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                              ),
                              splashColor: primary.withOpacity(0.2),
                              onTap: () {},
                            ),
                            Text(
                              "00",
                              style: Theme.of(context).textTheme.caption,
                            ),
                            InkWell(
                              child: Container(
                                margin: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.add,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                              ),
                              splashColor: primary.withOpacity(0.2),
                              onTap: () {},
                            ),
                          ],
                        ),
                        Spacer(),
                        Row(
                          children: <Widget>[
                            Text(
                              CUR_CURRENCY +
                                  "" +
                                  productList[index].prVarientList[0].price,
                              style:
                                  Theme.of(context).textTheme.overline.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                            ),
                            Text(
                                " " +
                                    CUR_CURRENCY +
                                    " " +
                                    productList[index]
                                        .prVarientList[0]
                                        .disPrice,
                                style: Theme.of(context).textTheme.headline6),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
        splashColor: primary.withOpacity(0.2),
        onTap: () {
          Product model = productList[index];
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Product_Detail(
                      model: model,
                     // title: productList[index].name,
                    )),
          );
        },
      ),
    );
  }

  Future<void> searchOperation(String searchText) async {
    searchresult.clear();

    for (var i = 0; i < productList.length; i++) {
      Product data = productList[i];

      if (data.name.toLowerCase().contains(searchText.toLowerCase()) ||
          data.desc.toLowerCase().contains(searchText.toLowerCase())) {
        searchresult.add(data);

        print("search result***${data.name}");
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> getProduct() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      try {
        Response response = await post(
          getProductApi,
          headers: headers,
        ).timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        //  print('response***product**$parameter****$headers***${response.body.toString()}');
        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          productList =
              (data as List).map((data) => new Product.fromJson(data)).toList();
        } else {
          if (msg != "Products Not Found !") setSnackbar(msg);
        }
        /* setState(() {
          _isLoading = false;
        });*/
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        /* setState(() {
          _isLoading = false;
        });*/
      }
    } else
      setSnackbar(internetMsg);
  }

  setSnackbar(String msg) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 1.0,
    ));
  }
}

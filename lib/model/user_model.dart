class UserModel{
  final String uid;
  UserModel({required this.uid});




}

class UserData{
  final String? uid;
  final String? name;
  final String? sugar;
  final int? strenght;

  UserData( {this.name,this.sugar, this.strenght, this.uid });
}
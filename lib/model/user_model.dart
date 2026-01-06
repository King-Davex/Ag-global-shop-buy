class UserModel{
  final String uid;
  UserModel({required this.uid});




}

class UserData{
  final String? uid;
  final String? name;
  final int? strenght;
  final String? photoUrl;
  final String? description;
  final bool? isBuying;

  UserData({this.name, this.strenght, this.uid, this.photoUrl, this.description, this.isBuying});
}
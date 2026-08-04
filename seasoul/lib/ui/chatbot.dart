// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class chatbot extends StatefulWidget {
//   const chatbot({super.key});

//   @override
//   State<chatbot> createState() => _chatbotState();
// }

// class _chatbotState extends State<chatbot> {
//   final GeminiService service = GeminiService();
//   final TextEditingController controller = TextEditingController();
//   final ScrollController scrollController = ScrollController();

//   List<Map<String, String>> messages = [];
//   bool isLoading = false;
//   bool hasText = false;

//   @override
//   void initState() {
//     super.initState();
//     controller.addListener(() {
//       setState(() {
//         hasText = controller.text.trim().isNotEmpty;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     scrollController.dispose();
//     super.dispose();
//   }

//   void sendMessage() async {
//     final text = controller.text.trim();
//     if (text.isEmpty || isLoading) return;

//     controller.clear();

//     setState(() {
//       messages.add({"role": "user", "text": text});
//       isLoading = true;
//     });

//     scrollToBottom();

//     final reply = await service.sendMessage(text);

//     setState(() {
//       messages.add({"role": "bot", "text": reply});
//       isLoading = false;
//     });

//     scrollToBottom();
//   }

//   void scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 200), () { 
//       if (scrollController.hasClients) {
//         scrollController.animateTo(
//           scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 350),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 15, 13, 41),
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 15, 13, 41),
//         elevation: 0,
//         surfaceTintColor: Color.fromARGB(255, 163, 163, 216),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: const Color(0xFFE8EAF0)),
//         ),leading: IconButton(
//   icon: const Icon(Icons.arrow_back, color: Colors.white),
//   onPressed: () => Navigator.pop(context),
// ),
//         title: Row(
//           children: [
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Sea Soul AI',
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Color.fromARGB(255, 163, 163, 216),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Container(
//                       width: 6,
//                       height: 6,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF4CAF50),
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     const Text(
//                       'Online',
//                       style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           Container(
//             height: 30,
//             width: 110,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(50),
//               color: Color(0xFF6C63FF).withOpacity(0.25),
//             ),
//             child: TextButton.icon(
//               onPressed: () {
//                 setState(() => messages = []);
//               },
//               icon: Icon(Icons.add, size: 16, color: Color(0xFF6C63FF)),
//               label: Text(
//                 'New chat',
//                 style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: messages.isEmpty && !isLoading
//                 ? buildEmptyState()
//                 : buildMessageList(),
//           ),
//           buildInputArea(),
//         ],
//       ),
//     );
//   }

//   Widget buildEmptyState() {
//     final suggestions = [
//       '🏄 Best rides in Lakshadweep',
//       '🍛 Best foods in Lakshadweep',
//       '🗺️ Best places in Lakshadweep',
//       '☀️ Current climate in Lakshadweep',
//     ];

//     return Center(
//       child: SingleChildScrollView(
//         padding: EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(height: 20),
//             Text(
//               'How can I help you today?',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Color.fromARGB(255, 163, 163, 216),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Ask me anything — powered by Sea Soul',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Color.fromARGB(255, 163, 163, 216),
//               ),
//             ),
//             const SizedBox(height: 28),
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               alignment: WrapAlignment.center,
//               children: suggestions.map((s) {
//                 return GestureDetector(
//                   onTap: () {
//                     final clean = s.split('  ').last;
//                     controller.text = clean;
//                     setState(() => hasText = true);
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xFFE8EAF0)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Color.fromARGB(
//                             255,
//                             163,
//                             163,
//                             216,
//                           ).withOpacity(0.04),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Text(
//                       s,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Color(0xFF4A5568),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildMessageList() {
//     return ListView.builder(
//       controller: scrollController,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       itemCount: messages.length + (isLoading ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == messages.length) {
//           return buildTypingBubble();
//         }
//         return buildMessageBubble(messages[index]);
//       },
//     );
//   }

//   Widget buildMessageBubble(Map<String, String> msg) {
//     final isUser = msg['role'] == 'user';

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         mainAxisAlignment: isUser
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         children: [
//           if (!isUser)
//             Container(
//               width: 25,
//               height: 32,
//               margin: const EdgeInsets.only(right: 8, bottom: 2),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF6C63FF),
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               child: Image.asset(
//                 'assets/images/image.png',
//                 width: 32,
//                 height: 32,
//                 fit: BoxFit.cover,
//               ),
//             ),

//           Flexible(
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.72,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
//               decoration: BoxDecoration(
//                 color: isUser
//                     ? const Color(0xFF6C63FF)
//                     : const Color(0xFF6C63FF).withOpacity(0.25),
//                 borderRadius: BorderRadius.circular(30),
//                 boxShadow: [
//                   BoxShadow(
//                     color: isUser
//                         ? const Color(0xFF6C63FF).withOpacity(0.25)
//                         : Colors.black.withOpacity(0.06),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: SelectableText(
//                 msg['text'] ?? '',
//                 style: TextStyle(
//                   color: isUser ? Colors.white : Colors.white,
//                   fontSize: 15,
//                   height: 1.5,
//                 ),
//               ),
//             ),
//           ),

//           if (isUser)
//             Container(
//               child: const Icon(Icons.person, color: Colors.white, size: 18),
//               width: 32,
//               height: 32,
//               margin: const EdgeInsets.only(left: 8, bottom: 2),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE8EAF0),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget buildTypingBubble() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             margin: const EdgeInsets.only(right: 8, bottom: 2),
//             decoration: BoxDecoration(
//               color: const Color(0xFF6C63FF),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Image.asset(
//               'assets/images/image.png',
//               width: 32,
//               height: 32,
//               fit: BoxFit.cover,
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Color(0xFF6C63FF).withOpacity(0.25),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(18),
//                 topRight: Radius.circular(18),
//                 bottomLeft: Radius.circular(4),
//                 bottomRight: Radius.circular(18),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: const TypingDots(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildInputArea() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
//       decoration: const BoxDecoration(
//         color: const Color.fromARGB(255, 15, 13, 41),
//         border: Border(top: BorderSide(color: Color(0xFFE8EAF0))),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Expanded(
//             child: Container(
//               constraints: const BoxConstraints(maxHeight: 130),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF7F8FC),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: const Color(0xFFE0E3ED)),
//               ),
//               child: TextField(
//                 controller: controller,
//                 maxLines: null,
//                 keyboardType: TextInputType.multiline,
//                 style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
//                 decoration: const InputDecoration(
//                   hintText: 'Message Sea Soul',
//                   hintStyle: TextStyle(color: Color(0xFFB0B8CC), fontSize: 15),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 18,
//                     vertical: 12,
//                   ),
//                 ),
//                 onSubmitted: (_) => sendMessage(),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),

//           AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: (hasText && !isLoading)
//                   ? const Color(0xFF6C63FF)
//                   : const Color(0xFFE8EAF0),
//               borderRadius: BorderRadius.circular(23),
//               boxShadow: (hasText && !isLoading)
//                   ? [
//                       BoxShadow(
//                         color: const Color(0xFF6C63FF).withOpacity(0.35),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ]
//                   : [],
//             ),
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(23),
//                 onTap: (hasText && !isLoading) ? sendMessage : null,
//                 child: Center(
//                   child: isLoading
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.5,
//                             color: Color(0xFF6C63FF),
//                           ),
//                         )
//                       : Icon(
//                           Icons.arrow_upward_rounded,
//                           color: (hasText && !isLoading)
//                               ? Colors.white
//                               : const Color(0xFFB0B8CC),
//                           size: 20,
//                         ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TypingDots extends StatefulWidget {
//   const TypingDots({super.key});

//   @override
//   State<TypingDots> createState() => _TypingDotsState();
// }

// class _TypingDotsState extends State<TypingDots>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(3, (i) {
//             final delay = i / 3;
//             final t = (_controller.value - delay).clamp(0.0, 1.0);
//             final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
//             return Transform.translate(
//               offset: Offset(0, -5 * bounce),
//               child: Container(
//                 width: 7,
//                 height: 7,
//                 margin: const EdgeInsets.symmetric(horizontal: 3),
//                 decoration: BoxDecoration(
//                   color: Color.lerp(
//                     const Color(0xFFCDD0DC),
//                     const Color(0xFF6C63FF),
//                     bounce,
//                   ),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

// class GeminiService {
//   final String apiKey = "AIzaSyB3y4rKNHuXdAZW0KEHQbwWykQgdAXXyuk";

//   List<Map<String, dynamic>> history = [];

//   Future<String> sendMessage(String text) async {
//     try {
//       history.add({
//         "role": "user",
//         "parts": [
//           {"text": text},
//         ],
//       });

//       final response = await http
//           .post(
//             Uri.parse(
//               "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
//             ),
//             headers: {"Content-Type": "application/json"},
//             body: jsonEncode({"contents": history}),
//           )
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode != 200) {
//         return "Server Error: ${response.statusCode}\n${response.body}";
//       }

//       final data = jsonDecode(response.body);

//       if (data == null ||
//           data["candidates"] == null ||
//           data["candidates"].isEmpty) {
//         return "Error: Empty response from AI";
//       }

//       final aiContent = data["candidates"][0]["content"];

//       if (aiContent == null || aiContent["parts"] == null) {
//         return "Error: Invalid response format";
//       }

//       final reply = aiContent["parts"][0]["text"] ?? "No response";

//       history.add(aiContent);

//       return reply;
//     } catch (e) {
//       return "Network/Error: $e";
//     }
//   }
// }



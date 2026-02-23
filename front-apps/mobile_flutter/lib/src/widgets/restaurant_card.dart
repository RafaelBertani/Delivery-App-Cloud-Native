import 'package:flutter/material.dart';

const String defaultLogo = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOpen = restaurant['is_open'] == true;
    final String logo = restaurant['logo'] ?? defaultLogo;

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Imagem do Restaurante
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOpen ? Colors.green : Colors.grey,
                    width: 3,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(logo),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Nome
              Text(
                restaurant['name'] ?? 'Sem Nome',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Badge Aberto/Fechado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  isOpen ? 'Aberto Agora' : 'Fechado',
                  style: TextStyle(
                    color: isOpen ? Colors.green.shade700 : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Descrição
              Expanded(
                child: Text(
                  restaurant['description'] ?? "O melhor da gastronomia na sua região.",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              
              const Divider(),

              // Localização
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${restaurant['city'] ?? ''} ${restaurant['state'] != null ? '- ${restaurant['state']}' : ''}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
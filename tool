import hashlib
import threading
import time
import os

# Thread'ler arası güvenli sayaç için kilit (Lock)
lock = threading.Lock()
attempts = 0
found = False

def hash_password(password, algorithm="sha256"):
    try:
        if algorithm == "sha256":
            return hashlib.sha256(password.encode('utf-8', errors='ignore')).hexdigest()
        elif hashlib.md5:
            return hashlib.md5(password.encode('utf-8', errors='ignore')).hexdigest()
    except Exception:
        return None

def worker(target_hash, word_chunk, algorithm):
    global attempts, found
    for word in word_chunk:
        if found:
            return
        
        word = word.strip()
        current_hash = hash_password(word, algorithm)
        
        with lock:
            attempts += 1
            if attempts % 1000 == 0:
                print(f"[*] Taranan deneme sayısı: {attempts}...", end="\r")
        
        if current_hash == target_hash:
            found = True
            print(f"\n\n[+] PAROLA KESİN OLARAK BULUNDU!")
            print(f"    Doğru Şifre : {word}")
            print(f"    Algoritma  : {algorithm.upper()}")
            print(f"    Deneme     : {attempts}")
            return

def load_wordlist_and_attack(target_hash, file_path, algorithm="sha256", thread_count=8):
    global attempts, found
    attempts = 0
    found = False

    if not os.path.exists(file_path):
        print(f"[-] Hata: {file_path} dosyası bulunamadı! Lütfen aynı dizine bir wordlist.txt ekle.")
        return

    print(f"[*] Wordlist okunuyor: {file_path}")
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        words = f.readlines()

    total_words = len(words)
    print(f"[+] Toplam {total_words} kelime yüklendi. {thread_count} thread ile saldırı başlatılıyor...\n")
    
    start_time = time.time()

    # Kelime listesini thread sayısına göre parçalara bölüyoruz (Multi-threading performans için şart)
    chunk_size = total_words // thread_count
    threads = []

    for i in range(thread_count):
        start_idx = i * chunk_size
        end_idx = (i + 1) * chunk_size if i != thread_count - 1 else total_words
        chunk = words[start_idx:end_idx]
        
        t = threading.Thread(target=worker, args=(target_hash, chunk, algorithm))
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    elapsed_time = time.time() - start_time

    if not found:
        print(f"\n[-] Tarama tamamlandı. Şifre bu listede yok. Geçen süre: {elapsed_time:.2f} saniye.")
    else:
        print(f"[*] Toplam Geçen Süre: {elapsed_time:.2f} saniye.")

if __name__ == "__main__":
    print("=" * 50)
    print("     KUWNOX - PROFESSIONAL MULTI-THREADED BRUTE-FORCE")
    print("=" * 50)

    # Test için hedef şifre ve algoritma seçimi
    target_plain = "fenerbahce1907"
    algo = "sha256"
    target_hash = hash_password(target_plain, algo)

    print(f"[#] Hedef Hash ({algo.upper()}): {target_hash}")
    print(f"[#] (Test amaçlı gizli şifre 'fenerbahce1907' olarak ayarlandı)\n")

    # Yanına aynı klasöre 'wordlist.txt' adında bir dosya oluşturup içine alt alta kelimeler yazabilirsin
    wordlist_filename = "wordlist.txt"
    
    # Eğer wordlist.txt yoksa otomatik test için geçici bir dosya oluşturalım
    if not os.path.exists(wordlist_filename):
        print(f"[*] '{wordlist_filename}' bulunamadı, test için otomatik oluşturuluyor...")
        with open(wordlist_filename, "w", encoding="utf-8") as f:
            f.write("admin123\nroot\npassword123\nankara06\nizmir35\nfenerbahce1907\nzaha10\n")

    load_wordlist_and_attack(target_hash, wordlist_filename, algorithm=algo, thread_count=4)

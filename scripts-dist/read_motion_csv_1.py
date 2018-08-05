import os
from csv import reader

for root, dirs, files in os.walk('/srv/www/media/videos/') :
  sortedFiles = sorted(files)

  for name in sortedFiles :
#   file_count += 1
    infile = os.path.join(root, name)
#    print(infile)

    if infile.endswith(".csv") :


      with open(infile, 'r') as csv_file:
        data = list(reader(csv_file))

        print(infile)
        for i in range(2, len(data)) :
#          print(data[i])
          if abs(int(data[i][4])) != int(data[i][5]):
            print(data[i])

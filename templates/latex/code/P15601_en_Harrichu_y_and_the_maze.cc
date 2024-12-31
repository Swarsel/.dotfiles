#include <iostream>
#include <queue>
#include <vector>
using namespace std;

struct coord {
    int x,y;
    coord (int xx=0, int yy=0) : x(xx), y(yy) {}
    bool operator== (const coord& p) {return x==p.x and y==p.y;}
} beg, goal;

int main () {
    int n;
    cin >> n;
    while (n--) {
        int r,c;
        cin >> r >> c;
        vector <vector <bool> > v (r, vector <bool> (c, 0));
        for (int i = 0; i < r; ++i)
            for (int j = 0; j < c; ++j) {
                char cc;
                cin >> cc;
                if (cc=='.') v[i][j]=true;
                else if (cc=='b') beg = coord(i,j);
                else if (cc=='g') goal = coord(i,j);
            }

        v[goal.x][goal.y] = v[beg.x][beg.y]=true;
        vector <vector <bool> > f (v.size(),vector <bool> (v[0].size(),0));

        queue <coord> q;
        q.push(beg);

        while (!q.empty()) {
            coord p = q.front(); q.pop();
            if (p.x>=v.size() or p.x<0 or p.y >= v[0].size() or p.y<0) continue;
            if (!v[p.x][p.y]) continue;
            if (f[p.x][p.y]) continue;

            f[p.x][p.y] = true;
            if (p==goal) break;

            q.push(coord(p.x+1,p.y));
            q.push(coord(p.x-1,p.y));
            q.push(coord(p.x,p.y+1));
            q.push(coord(p.x,p.y-1));
        }

        cout << (f[goal.x][goal.y]? "Good" : "Bad") << endl;
    }
}

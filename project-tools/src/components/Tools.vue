<template>
  <div class="hello">
    <div class="filter">
      <div><span>本金: </span><input v-model="source" /></div>
      <div class="filter-date">
        <span>日期:</span>
        <input v-model="year" />年 -
        <input v-model="month" />月 -
        <input v-model="day" />日
      </div>
      <div>
        <span>期数:</span>
        <select v-model="times">
          <option value="3">3个月</option>
          <option value="6">6个月</option>
          <option value="12">12个月</option>
        </select>
      </div>
      <div class="sxf">
        <span>充值手续费: </span><input v-model="czSxf" />
      </div>
      <div class="sxf">
        <span>放款/提现手续费: </span><input v-model="txSxf" />
      </div>
    </div>

    <div>
      <table cellspacing="0" cellpadding="5px">
        <tr>
          <th>期次</th>
          <th>支付日期</th>
          <th>总额</th>
          <th>本金</th>
          <th>利息</th>
          <th>居间管理费</th>
          <th>诚信保证金</th>
          <th>充值手续费</th>
          <th>放款/提现手续费</th>
        </tr>
        <tr v-for="result in results">
          <td>{{ result.index }}</td>
          <td>{{ result.date }}</td>
          <td>{{ result.total }}</td>
          <td>{{ result.source }}</td>
          <td>{{ result.lx }}</td>
          <td>{{ result.glf }}</td>
          <td>{{ result.bzj }}</td>
          <td>{{ result.cz_sxf }}</td>
          <td>{{ result.tx_sxf }}</td>
        </tr>
      </table>
    </div>
  </div>
</template>

<script>
import moment from 'moment';
const percMap = {
  '3': {
    nlx: 0.08,
    glf: 0.1
  },
  '6': {
    nlx: 0.09,
    glf: 0.09
  },
  '12': {
    nlx: 0.105,
    glf: 0.075
  }
};
export default {
  name: 'hello',
  data () {
    return {
      source: '256900',
      year: '2017',
      month: '5',
      day: '3',
      czSxf: '0',
      txSxf: '3',
      times: '3'
    };
  },
  computed: {
    results() {
      let {source, year, month, day, times} = this;
      source = source.trim();
      year = year.trim();
      month = month.trim();
      day = day.trim();
      if (!source || !year || !month || !day) {
        return [];
      }   
      source = parseInt(source);

      let timesNum = parseInt(times);
      let formatFloat = function(num, precise) {
        if (!precise) {
          precise = 2;
        }
        precise = Math.pow(10, precise);
        return Math.round(num * precise) / precise;  
      };

      let lxPerMonth = formatFloat(percMap[times].nlx * source / 12);
      let glfPerMonth = formatFloat(source * 0.18 / 12 - lxPerMonth);
      let resultList = [];

      let startDate = new Date(year + '/' + month + '/' + day);
      let format = function(days) {
        return moment(startDate).add(days, 'days').format('YYYY-MM-DD');
      };

      let czSxf = parseInt(this.czSxf || 0);
      let txSxf = parseInt(this.txSxf || 0);

      // 添加第一期
      resultList.push({
        index: 1,
        date: format(0),
        total: formatFloat(lxPerMonth + glfPerMonth + source * 0.03 + txSxf + czSxf),
        source: 0,
        lx: lxPerMonth,
        glf: glfPerMonth,
        bzj: formatFloat(source * 0.03),
        cz_sxf: czSxf,
        tx_sxf: txSxf
      });

      // 添加其他期利息
      for (let dateIdx = 1; dateIdx < timesNum; dateIdx++) {
        resultList.push({
          index: dateIdx + 1,
          date: format(dateIdx * 30 - 1),
          total: formatFloat(lxPerMonth + glfPerMonth),
          source: 0,
          lx: lxPerMonth,
          glf: glfPerMonth,
          bzj: 0,
          cz_sxf: 0,
          tx_sxf: 0
        })
      }

      // 调整最后一期利息
      let totalLx = lxPerMonth * timesNum;
      let totalGlf = glfPerMonth * timesNum;
      if (totalLx > parseInt(totalLx)) {
        let lastResult = resultList[timesNum - 1];
        let diffLx = formatFloat((parseInt(totalLx) + 1 - totalLx) * 100 % 10 / 100);
        let diffGlf = formatFloat((parseInt(totalGlf) + 1 - totalGlf) * 100 % 10 / 100);
        
        if (diffLx < diffGlf) {
          lastResult.lx = formatFloat(lastResult.lx + diffLx);
          lastResult.glf = formatFloat(lastResult.glf - diffLx);
        } else {
          lastResult.lx = formatFloat(lastResult.lx - diffGlf);
          lastResult.glf = formatFloat(lastResult.glf + diffGlf);
        }
      }

      // 添加本金
      resultList.push({
        index: timesNum + 1,
        date: format(timesNum * 30 - 1),
        total: source,
        source: source,
        lx: 0,
        glf: 0,
        bzj: 0,
        cz_sxf: 0,
        tx_sxf: 0
      });

      // 计算总计
      let total = 0;
      totalLx = 0;
      totalGlf = 0;
      for (let resultIdx in resultList) {
        total += resultList[resultIdx].total;
        totalLx += resultList[resultIdx].lx;
        totalGlf += resultList[resultIdx].glf;
      }

      totalLx = formatFloat(totalLx, 1);
      totalGlf = formatFloat(totalGlf, 1);

      resultList.push({
        index: '总计',
        date: '-',
        total: total,
        source: source,
        lx: totalLx,
        glf: totalGlf,
        bzj: resultList[0].bzj,
        cz_sxf: czSxf,
        tx_sxf: resultList[0].tx_sxf
      });
      return resultList;
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.filter > div {
  padding: 10px 0;
}
.filter-date input {
  width: 50px;
}
table, th, td {
  border: 1px solid lightgray;
}
.sxf input {
  width: 80px;
}
</style>

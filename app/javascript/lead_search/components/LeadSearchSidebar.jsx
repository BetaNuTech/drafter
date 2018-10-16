import React from 'react'
import Style from './LeadSearchSidebar.scss'

class LeadSearchSidebar extends React.Component {

  getFilterData = (key) => {
    const filters = this.props.options.Filters
    return (filters && filters[key]) ? filters[key].values  : []
  }

  filterInfo = (key) => {
    const values = this.getFilterData(key)
    let output = ""
    if (values.length > 0) {
      output = values.map((value) => {
        return <li key={value.value}>{value.label}</li>
      })
    } else {
      output = <li>Any</li>
    }
    return output
  }

  render() {
    return(
      <div className={Style.LeadSearchSidebar}>
        <div className={Style.FilterListContainer}>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Search</span>
            <ul>
              {this.filterInfo("Search")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Priority</span>
            <ul>
              {this.filterInfo("Priorities")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Agent</span>
            <ul>
              {this.filterInfo("Agents")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Property</span>
            <ul>
              {this.filterInfo("Properties")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>State</span>
            <ul>
              {this.filterInfo("States")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Referrals</span>
            <ul>
              {this.filterInfo("Referrals")}
            </ul>
          </div>
          <div className={Style.FilterList}>
            <span className={Style.FilterListItem}>Sources</span>
            <ul>
              {this.filterInfo("Sources")}
            </ul>
          </div>
          <div className="clearfix"></div>
        </div>
      </div>
    );
  }
}

export default LeadSearchSidebar

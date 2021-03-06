import React from 'react'
import { Link } from 'react-router-dom';

type LinkItem = {
  text: string,
  link: string
}

type ListItem = {
  text: string
}

interface ListProps {
  items: Array<LinkItem|ListItem>
}

export const List: React.FC<ListProps> = ({items}) => {
  return (
    <ul>
      {
        items.map((item: LinkItem | ListItem, index) => {
          return 'link' in item ? (
            <li className="linkItem" key={index}><Link to={item.link}>{item.text}</Link></li>
          ) : (
            <li className="listItem" key={index}>{item.text}</li>
          )
        })
      }
    </ul>
  );
}
